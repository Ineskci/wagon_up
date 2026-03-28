require "net/http"
require "json"

class InterviewsController < ApplicationController
  ANTHROPIC_API_URL   = "https://api.anthropic.com/v1/messages"
  MODEL               = "claude-sonnet-4-5"
  MAX_TOKENS          = 1_000
  TEMPERATURE         = 0.7
  TECHNICAL_QUESTIONS = 3
  PERSONAL_QUESTIONS  = 2
  TOTAL_QUESTIONS     = TECHNICAL_QUESTIONS + PERSONAL_QUESTIONS

  SYSTEM_PROMPT = <<~PROMPT
    IMPORTANT: RESPOND EXCLUSIVELY IN ENGLISH. NEVER use Portuguese.

    ## Persona
    You are Chloé 2.0, interview coach at WagonUP.

    ## MANDATORY RULES
    - ALWAYS in English — no exceptions
    - ALWAYS one message at a time
    - NEVER put feedback and a question in the same message
    - NEVER use labels like "Question:", "Feedback:", "Technical:", "Personal:" before the text
    - Write directly without prefixes or titles

    ## Interview structure (#{TOTAL_QUESTIONS} questions total)
    - #{TECHNICAL_QUESTIONS} technical questions about technologies relevant to the role
    - #{PERSONAL_QUESTIONS} personal questions about motivation, career and goals

    ## Candidate profile
    The candidate is a Le Wagon bootcamp graduate — junior level, 3–6 months of coding experience.
    They know the fundamentals but have NOT worked professionally as a developer yet.
    Calibrate ALL technical questions to this level: bootcamp graduate, first job seeker.

    ## Technical questions — difficulty level: JUNIOR / ENTRY-LEVEL
    - Test understanding of CONCEPTS and FUNDAMENTALS, not advanced implementation
    - Good question: "What is a JOIN in SQL and when would you use it?"
    - Bad question: "Write a query using LEFT JOIN with NOT EXISTS and date filtering"
    - Good question: "What does Ruby on Rails MVC stand for and what is the role of each part?"
    - Bad question: "Explain how Rails handles concurrent requests with Puma thread pools"
    - Questions must be answerable by someone who completed a 9-week bootcamp
    - Open-ended questions — the candidate answers freely
    - If the answer is correct: congratulate warmly and briefly (1 line)
    - If incorrect: correct warmly. Explain the correct answer in at most 1 line
    - NEVER ask follow-up questions. After the feedback, STOP.

    ## Personal questions
    - Open-ended questions about motivation, career transition and professional goals
    - Feedback always positive and encouraging — there is no wrong answer
    - Connect the candidate's answer to the role and their journey at Le Wagon

    ## MANDATORY scoring criteria (0-10)
    Be HONEST. Giving high scores to weak answers does NOT help the candidate.
    - Score 0: empty, evasive answer, "I don't know", fewer than 10 words with no real effort
    - Score 1-3: vague, generic, no concrete examples
    - Score 4-5: reasonable but lacking depth or structure
    - Score 6-7: good, with examples and demonstrated transferable skills
    - Score 8-9: excellent, structured (STAR), with clear metrics or impact
    - Score 10: perfect — rarely given
    "I don't know" MUST receive score 0. Never round up so as not to demotivate.

    ## Format
    - No labels, no titles, no prefixes
    - Feedback: maximum 1-2 lines
    - Questions: direct and concise
  PROMPT

  PERSONAL_TOPICS  = ["motivation and career transition into tech", "strengths and professional goals"].freeze
  QUESTION_FORMAT  = "Ask a direct and concise question. Do not use options A, B, C — the candidate answers freely.".freeze

  FALLBACK_TOPICS_BY_PROGRAM = {
    "ai_software"      => ["Ruby on Rails", "JavaScript", "SQL", "OpenAI API", "Git"],
    "data_analytics"   => ["SQL", "Python", "Google Analytics", "Looker Studio", "Data Visualisation"],
    "data_science"     => ["Python", "SQL", "Machine Learning", "Data Wrangling", "Git"],
    "data_engineering" => ["Python", "SQL", "Data Pipelines", "ETL", "Git"],
    "growth_marketing" => ["Google Analytics", "SEO", "Google Ads", "CRM tools", "A/B Testing"]
  }.freeze
  DEFAULT_FALLBACK = ["Ruby on Rails", "JavaScript", "SQL", "HTML/CSS", "Git"].freeze

  # Respostas evasivas que recebem score 0 automaticamente sem chamar a API
  EVASIVE_PATTERN = /\A\s*\z|i\s*don'?t\s*know|no\s*idea|^idk$|^skip$|^nothing$|^pass$|^n\/a$/i

  # ── Actions ───────────────────────────────────────────────────────────────

  # GET /roles/:role_id/interviews/new
  def new
    @role       = current_user_role(params[:role_id])
    @interview  = Interview.new
    @interviews = Interview.joins(role: :analysis)
                           .where(analyses: { user_id: current_user.id }, roles: { id: @role.id })
                           .order(created_at: :desc)
  end

  # POST /roles/:role_id/interviews
  # Cria a entrevista e gera a primeira pergunta via API
  def create
    @role      = current_user_role(params[:role_id])
    @interview = Interview.new(role: @role, category: "técnica")

    if @interview.save
      begin
        topics = select_topics_for_role
        @interview.update!(selected_topics: topics.to_json)
        first_q = ask_fresh(first_question_prompt)
        @interview.answers.create!(question: first_q)
      rescue => e
        Rails.logger.error "InterviewsController#create API error: #{e.message}"
        @interview.destroy
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { error: "Could not generate the first question. Please try again." }, status: :unprocessable_entity }
        end
        return
      end

      respond_to do |format|
        format.html { redirect_to interview_path(@interview) }
        format.json { render json: { interview_id: @interview.id, first_question: first_q } }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: "Could not create the interview" }, status: :unprocessable_entity }
      end
    end
  end

  # GET /interviews/:id
  def show
    @interview  = current_user_interview(params[:id])
    @role       = @interview.role
    @interviews = Interview.joins(role: :analysis)
                           .where(analyses: { user_id: current_user.id }, roles: { id: @role.id })
                           .order(created_at: :desc)
  end

  # PATCH /interviews/:id
  # Recebe a resposta do user, avalia, guarda feedback e gera próxima pergunta
  def update
    @interview = current_user_interview(params[:id])
    @role      = @interview.role

    pending = @interview.answers.where(answer: nil).order(:created_at).last

    if pending.nil?
      respond_to do |format|
        format.html { redirect_to results_interview_path(@interview) }
        format.json { render json: { finished: true, results_url: results_interview_path(@interview) } }
      end
      return
    end

    # 1. Guarda a resposta do user
    pending.update!(answer: params[:answer])

    # 2. Constrói histórico e avalia a resposta
    build_conversation_history
    @user_count = @interview.answers.where.not(answer: nil).count

    begin
      process_response(pending)
    rescue => e
      Rails.logger.error "InterviewsController#update API error: #{e.message}"
    end

    pending.reload
    @interview.reload

    respond_to do |format|
      format.html { redirect_to interview_path(@interview) }
      format.json {
        next_answer = @interview.answers.where(answer: nil).order(:created_at).last
        render json: {
          feedback:      pending.feedback,
          score:         pending.score,
          next_question: next_answer&.question,
          finished:      @interview.overall_score.present?,
          results_url:   @interview.overall_score.present? ? results_interview_path(@interview) : nil
        }
      }
    end
  end

  # GET /interviews/:id/results
  def results
    @interview = current_user_interview(params[:id])
    @role      = @interview.role
  end

  private

  # ── Evasion gate ──────────────────────────────────────────────────────────

  def evasive_answer?(text)
    return true if text.blank? || text.strip.length < 5
    EVASIVE_PATTERN.match?(text.strip)
  end

  def zero_score_feedback
    "Score 0/10. In a real interview, this answer would be disqualifying. " \
    "Even without direct experience, use the STAR method: describe a similar Situation, " \
    "the Task you had, the Action you took and the Result. " \
    "Always give an example — it can be from a personal project or from Le Wagon. Try again!"
  end

  # ── Lógica de sequência ───────────────────────────────────────────────────

  def process_response(pending)
    case @user_count
    when 1..TOTAL_QUESTIONS - 1 then handle_mid_question(pending)
    when TOTAL_QUESTIONS        then handle_last_question(pending)
    end
  end

  def handle_mid_question(pending)
    if evasive_answer?(pending.answer)
      feedback = zero_score_feedback
      pending.update!(feedback: feedback, score: 0)
    else
      feedback = ask_fresh(feedback_prompt(pending))
      pending.update!(feedback: feedback, score: extract_score(feedback))
    end

    @history << { role: "assistant", content: feedback }

    next_q = ask(next_question_prompt)
    @interview.answers.create(question: next_q)
  end

  def handle_last_question(pending)
    if evasive_answer?(pending.answer)
      feedback = zero_score_feedback
      pending.update!(feedback: feedback, score: 0)
    else
      feedback = ask_fresh(feedback_prompt(pending))
      pending.update!(feedback: feedback, score: extract_score(feedback))
    end

    @history << { role: "assistant", content: feedback }

    summary = ask(summary_prompt)
    overall = @interview.answers.where.not(score: nil).pluck(:score).then do |scores|
      scores.any? ? (scores.sum.to_f / scores.size).round : 0
    end

    @interview.update!(overall_score: overall, feedback_summary: summary)
  end

  # ── Prompts ───────────────────────────────────────────────────────────────

  # Returns the 3 topics stored on the interview (set at creation time by Claude)
  def technical_topics
    return @technical_topics if defined?(@technical_topics)
    stored = @interview.selected_topics.presence
    @technical_topics = stored ? JSON.parse(stored) : fallback_topics
  end

  # One lightweight Claude call to pick the 3 most relevant skills for the role
  def select_topics_for_role
    candidate_skills = @role.analysis.hard_skills_selected.to_s
                            .split(/,\s*/).map(&:strip).reject(&:blank?)

    if candidate_skills.size < TECHNICAL_QUESTIONS
      candidate_skills = fallback_topics
    end

    prompt = <<~PROMPT
      The candidate is interviewing for the role: #{@role.title}.
      Role context: #{@role.justification}

      The candidate's confirmed technical skills are: #{candidate_skills.join(", ")}.

      Select exactly #{TECHNICAL_QUESTIONS} skills from the candidate's list that are MOST relevant to the #{@role.title} role.
      Return ONLY a JSON array of #{TECHNICAL_QUESTIONS} strings. No explanation. No markdown. Example: ["SQL","Python","Git"]
    PROMPT

    raw = ask_fresh(prompt)
    parsed = JSON.parse(raw.gsub(/```json|```/, "").strip)
    parsed.first(TECHNICAL_QUESTIONS)
  rescue
    fallback_topics
  end

  def fallback_topics
    program = @role.analysis.wagon_program.to_s
    (FALLBACK_TOPICS_BY_PROGRAM[program] || DEFAULT_FALLBACK).first(TECHNICAL_QUESTIONS)
  end

  def first_question_prompt
    "Ask the first technical question about #{technical_topics.first} " \
    "for the #{@role.title} role. #{QUESTION_FORMAT}"
  end

  def feedback_prompt(answer)
    if @user_count <= TECHNICAL_QUESTIONS
      "The question was: '#{answer.question}'.\n" \
      "The candidate's answer was: '#{answer.answer}'.\n\n" \
      "Evaluate the answer with a score from 0 to 10 following the system criteria.\n" \
      "If correct: congratulate warmly and briefly (1 line).\n" \
      "If incorrect: correct warmly and encouragingly. " \
      "Explain the correct answer in at most 1 line.\n" \
      "Do NOT ask any question. Do NOT say 'Let's move on'."
    else
      "The question was: '#{answer.question}'.\n" \
      "The candidate's answer was: '#{answer.answer}'.\n\n" \
      "Give warm and encouraging feedback about the answer (maximum 2 lines). " \
      "Value the candidate's perspective and connect it to the #{@role.title} role.\n" \
      "Do NOT ask any question. Do NOT say 'Let's move on'."
    end
  end

  def next_question_prompt
    if @user_count < TECHNICAL_QUESTIONS
      topic = technical_topics[@user_count]
      "Ask the next technical question about #{topic} " \
      "for the #{@role.title} role. #{QUESTION_FORMAT}"
    else
      personal_index = @user_count - TECHNICAL_QUESTIONS
      topic = PERSONAL_TOPICS[personal_index]
      "Ask a personal question about #{topic} for the candidate applying to the #{@role.title} role. " \
      "The question should be open-ended and encouraging. Do not use options A, B, C."
    end
  end

  def summary_prompt
    "Based on all the candidate's answers to the #{TOTAL_QUESTIONS} questions, " \
    "give honest overall feedback for the #{@role.title} role. " \
    "Highlight the strengths and a single improvement suggestion. Maximum 4 lines."
  end

  # ── API calls ─────────────────────────────────────────────────────────────

  def ask(prompt)
    messages = @history.dup
    messages << { role: "user", content: prompt }
    call_api(messages)
  end

  def ask_fresh(prompt)
    call_api([{ role: "user", content: prompt }])
  end

  def call_api(messages)
    uri  = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"]      = "application/json"
    request["x-api-key"]         = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model:       MODEL,
      max_tokens:  MAX_TOKENS,
      temperature: TEMPERATURE,
      system:      system_with_role_context,
      messages:    messages
    }.to_json

    response = http.request(request)
    body     = JSON.parse(response.body)
    body.dig("content", 0, "text").to_s.strip
  end

  def system_with_role_context
    SYSTEM_PROMPT + "\n\nRole being interviewed for: #{@role&.title}. #{@role&.justification}"
  end

  def build_conversation_history
    @history = []
    @interview.answers.order(:created_at).each do |a|
      @history << { role: "assistant", content: a.question }  if a.question.present?
      @history << { role: "user",      content: a.answer }    if a.answer.present?
      @history << { role: "assistant", content: a.feedback }  if a.feedback.present?
    end
  end

  # Extrai score do texto de feedback — tenta ler número explícito primeiro
  def extract_score(feedback_text)
    if (match = feedback_text.match(/\b([0-9]|10)\s*\/\s*10\b/))
      return match[1].to_i
    end
    positive = feedback_text.match?(/congratulations|correct|excellent|well done|great|perfect|right/i)
    positive ? rand(7..9) : rand(3..5)
  end

  # ── Authorization helpers ─────────────────────────────────────────────────

  def interview_params
    params.require(:interview).permit(:category, :overall_score, :feedback_summary)
  end

  def current_user_role(role_id)
    Role.joins(:analysis).where(analyses: { user_id: current_user.id }, id: role_id).first!
  end

  def current_user_interview(interview_id)
    Interview.joins(role: :analysis).where(analyses: { user_id: current_user.id }, id: interview_id).first!
  end
end
