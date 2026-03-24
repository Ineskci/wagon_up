class AnswersController < ApplicationController
  EVASIVE_PATTERNS = [
    /\A\s*\z/i,
    /\A.{0,4}\z/m,
    /\A(n[aã]o sei|nao sei|sei l[aá]|passo|skip|nada|idk|i don't know|no idea|n sei|ns)\z/i
  ].freeze

  # POST /interviews/:interview_id/answers
  def create
    @interview = Interview
      .joins(role: :analysis)
      .where(analyses: { user_id: current_user.id }, id: params[:interview_id])
      .first!

    @answer = Answer.new(answer_params)
    @answer.interview = @interview

    if evasive_answer?(@answer.answer)
      @answer.score = 0
      @answer.feedback = feedback_resposta_evasiva
    else
      result = ChloeInterviewer.new(@interview).evaluate_answer(@answer.question, @answer.answer)
      @answer.score = result[:score]
      @answer.feedback = result[:feedback]
    end

    if @answer.save
      @interview.finalize! if @interview.completed?
      redirect_to interview_path(@interview), notice: "Resposta guardada!"
    else
      redirect_to interview_path(@interview), alert: "Erro ao guardar a resposta."
    end
  end

  private

  def answer_params
    params.require(:answer).permit(:question, :answer)
  end

  def evasive_answer?(text)
    normalized = text.to_s.strip.downcase
    return true if normalized.blank?

    EVASIVE_PATTERNS.any? { |pattern| normalized.match?(pattern) }
  end

  def feedback_resposta_evasiva
    <<~TEXT.strip
      Score: 0/10. Numa entrevista real, uma resposta vazia ou “não sei” pode ser eliminatória.
      Mesmo sem experiência direta, tente estruturar sua resposta com o método STAR (Situação, Tarefa, Ação, Resultado)
      e usar exemplos de projetos, estudos ou desafios pessoais.
    TEXT
  end
end
