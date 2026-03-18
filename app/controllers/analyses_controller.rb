class AnalysesController < ApplicationController
  # GET /analyses/new
  # Mostra o formulário de upload do CV
  # Cria um objeto Analysis vazio para o formulário
  def new
    @analysis = Analysis.new
  end

  # POST /analyses
  # Recebe o formulário com o CV e cria a analysis
  # Associa automaticamente ao utilizador autenticado (current_user)
  # Após guardar, redireciona para a página da analysis (show)
  # TODO: chamar ClaudeAnalyser.call(@analysis) aqui para gerar os 3 roles via API Anthropic
  def create
    @analysis = Analysis.new(analysis_params)
    @analysis.user = current_user

    if @analysis.save
      redirect_to analysis_path(@analysis), notice: "CV enviado! A IA está a analisar o teu perfil."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /analyses/:id
  # Mostra o resultado da análise com os 3 roles sugeridos
  # @roles ordenados por position (1, 2, 3) — ordem de recomendação da IA
  def show
    @analysis = Analysis.find(params[:id])
    @roles = @analysis.roles.order(:position)
  end

  private

  # Filtra os parâmetros permitidos vindos do formulário
  # :cv_text — texto do CV colado/digitado pelo user
  # :file    — ficheiro PDF do CV (Active Storage)
  def analysis_params
    params.require(:analysis).permit(:cv_text, :file)
  end
end
