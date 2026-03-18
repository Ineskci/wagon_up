class InterviewsController < ApplicationController
  # GET /roles/:role_id/interviews/new
  # Mostra o formulário para iniciar uma entrevista para um role específico
  # role_id vem da URL (nested route) — sabemos para qual role é a entrevista
  def new
    @role = Role.find(params[:role_id])
    @interview = Interview.new
  end

  # POST /roles/:role_id/interviews
  # Cria a entrevista ligada ao role escolhido pelo user
  # role_id vem da URL (nested route)
  # Após criar, redireciona para a entrevista em curso (show)
  # TODO: chamar ChloeInterviewer.call(@interview) para gerar as perguntas via API Anthropic
  def create
    @role = Role.find(params[:role_id])
    @interview = Interview.new(interview_params)
    @interview.role = @role

    if @interview.save
      redirect_to interview_path(@interview), notice: "Entrevista iniciada! Boa sorte."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /interviews/:id
  # Página principal da entrevista em curso
  # Mostra as perguntas e o formulário para submeter respostas
  # @answers ordenadas por created_at — mostra a conversa em ordem cronológica
  def show
    @interview = Interview.find(params[:id])
    @answers = @interview.answers.order(:created_at)
    @role = @interview.role
  end

  # PATCH /interviews/:id
  # Actualiza a entrevista com o score final e feedback da IA
  # Chamado quando a ChloeInterviewer termina de avaliar todas as respostas
  # Redireciona para a página de resultados
  def update
    @interview = Interview.find(params[:id])

    if @interview.update(interview_params)
      redirect_to results_interview_path(@interview)
    else
      render :show, status: :unprocessable_entity
    end
  end

  # GET /interviews/:id/results
  # Página final da entrevista com score global e feedback detalhado
  # Mostra todas as respostas com a avaliação da IA para cada uma
  def results
    @interview = Interview.find(params[:id])
    @answers = @interview.answers.order(:created_at)
    @role = @interview.role
  end

  private

  # Filtra os parâmetros permitidos vindos do formulário
  # :category        — tipo de entrevista (ex: "técnica", "comportamental")
  # :overall_score   — score final gerado pela IA (0-100)
  # :feedback_summary — resumo do feedback da IA sobre a entrevista completa
  def interview_params
    params.require(:interview).permit(:category, :overall_score, :feedback_summary)
  end
end
