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
    IMPORTANTE: RESPONDA EXCLUSIVAMENTE EM PORTUGUÊS DO BRASIL. NUNCA use inglês.

    ## Persona
    Você é Chloé 2.0, coach de entrevistas do Le Wagon Brasil.

    ## Regras OBRIGATÓRIAS
    - SEMPRE em português do Brasil — sem excepção
    - SEMPRE uma mensagem por vez
    - NUNCA coloque feedback e pergunta na mesma mensagem
    - NUNCA use labels como "Pergunta:", "Feedback:", "Técnica:", "Pessoal:" antes do texto
    - Escreva directamente sem prefixos ou títulos

    ## Estrutura da entrevista (#{TOTAL_QUESTIONS} perguntas no total)
    - #{TECHNICAL_QUESTIONS} perguntas técnicas sobre tecnologias relevantes para o cargo
    - #{PERSONAL_QUESTIONS} perguntas pessoais sobre motivação, carreira e objectivos

    ## Perguntas técnicas
    - Perguntas abertas — o candidato responde livremente
    - Se a resposta estiver correcta: parabenize de forma calorosa e breve (1 linha)
    - Se estiver incorrecta: corrija de forma calorosa. Explique a resposta correcta em máximo 1 linha
    - NUNCA faças perguntas de follow-up. Depois do feedback, PARE.

    ## Perguntas pessoais
    - Perguntas abertas sobre motivação, transição de carreira e objectivos profissionais
    - Feedback sempre positivo e encorajador — não há resposta errada
    - Conecta a resposta do candidato ao cargo e à sua jornada no Le Wagon

    ## Critérios de scoring OBRIGATÓRIOS (0-10)
    Sê HONESTA. Dar scores altos a respostas fracas NÃO ajuda o candidato.
    - Score 0: resposta vazia, evasiva, "não sei", menos de 10 palavras sem esforço real
    - Score 1-3: vaga, genérica, sem exemplos concretos
    - Score 4-5: razoável mas sem profundidade nem estrutura
    - Score 6-7: boa, com exemplos e transferable skills demonstradas
    - Score 8-9: excelente, estruturada (STAR), com métricas ou impacto claro
    - Score 10: perfeita — raramente dada
    "Não sei" DEVE receber score 0. Nunca arredondas para cima para não desmotivar.

    ## Formato
    - Sem labels, sem títulos, sem prefixos
    - Feedback: máximo 1-2 linhas
    - Perguntas: directas e concisas
  PROMPT

  TECHNICAL_TOPICS = ["Ruby on Rails", "JavaScript", "SQL"].freeze
  PERSONAL_TOPICS  = ["motivação e transição de carreira para tech", "pontos fortes e objectivos profissionais"].freeze
  QUESTION_FORMAT  = "Faça uma pergunta directa e concisa. Não uses opções A, B, C — o candidato responde livremente.".freeze

  # Respostas evasivas que recebem score 0 automaticamente sem chamar a API
  EVASIVE_PATTERN = /\A\s*\z|não\s*sei|nao\s*sei|sei\s*l[aá]|^passo$|^skip$|^nada$|^idk$|i\s*don'?t\s*know|no\s*idea|n\s*sei|^ns$/i

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
        first_q = ask_fresh(first_question_prompt)
        @interview.answers.create!(question: first_q)
      rescue => e
        Rails.logger.error "InterviewsController#create API error: #{e.message}"
        @interview.destroy
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { error: "Não foi possível gerar a primeira pergunta. Tenta novamente." }, status: :unprocessable_entity }
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
        format.json { render json: { error: "Não foi possível criar a entrevista" }, status: :unprocessable_entity }
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
    "Score 0/10. Numa entrevista real esta resposta seria eliminatória. " \
    "Mesmo sem experiência directa, usa o método STAR: descreve uma Situação similar, " \
    "a Tarefa que tinhas, a Acção que tomaste e o Resultado. " \
    "Dá sempre um exemplo — pode ser de um projecto pessoal ou do Le Wagon. Tenta de novo!"
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

  def first_question_prompt
    "Faça a primeira pergunta técnica sobre #{TECHNICAL_TOPICS.first} " \
    "para o cargo de #{@role.title}. #{QUESTION_FORMAT}"
  end

  def feedback_prompt(answer)
    if @user_count <= TECHNICAL_QUESTIONS
      "A pergunta foi: '#{answer.question}'.\n" \
      "A resposta do candidato foi: '#{answer.answer}'.\n\n" \
      "Avalia a resposta com um score de 0 a 10 seguindo os critérios do sistema.\n" \
      "Se estiver correcta: parabenize de forma calorosa e breve (1 linha).\n" \
      "Se estiver incorrecta: corrija de forma calorosa e encorajadora. " \
      "Explique a resposta correcta em máximo 1 linha.\n" \
      "NÃO faças nenhuma pergunta. NÃO digas 'Vamos para a próxima'."
    else
      "A pergunta foi: '#{answer.question}'.\n" \
      "A resposta do candidato foi: '#{answer.answer}'.\n\n" \
      "Dê um feedback caloroso e encorajador sobre a resposta (máximo 2 linhas). " \
      "Valorize a perspectiva do candidato e conecta com o cargo de #{@role.title}.\n" \
      "NÃO faças nenhuma pergunta. NÃO digas 'Vamos para a próxima'."
    end
  end

  def next_question_prompt
    if @user_count < TECHNICAL_QUESTIONS
      topic = TECHNICAL_TOPICS[@user_count]
      "Faça a próxima pergunta técnica sobre #{topic} " \
      "para o cargo de #{@role.title}. #{QUESTION_FORMAT}"
    else
      personal_index = @user_count - TECHNICAL_QUESTIONS
      topic = PERSONAL_TOPICS[personal_index]
      "Faça uma pergunta pessoal sobre #{topic} para o candidato ao cargo de #{@role.title}. " \
      "A pergunta deve ser aberta e encorajadora. Não uses opções A, B, C."
    end
  end

  def summary_prompt
    "Com base em todas as respostas do candidato às #{TOTAL_QUESTIONS} perguntas, " \
    "dê um feedback geral honesto para o cargo de #{@role.title}. " \
    "Destaca os pontos fortes e uma única sugestão de melhoria. Máximo 4 linhas."
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
    SYSTEM_PROMPT + "\n\nCargo entrevistado: #{@role&.title}. #{@role&.justification}"
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
    positive = feedback_text.match?(/parabéns|correcto|excelente|muito bem|ótimo|perfeito|certo/i)
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
