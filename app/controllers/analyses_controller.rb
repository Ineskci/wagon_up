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
    @analysis = current_user.analyses.new

    if params[:analysis][:file].blank?
      @analysis.errors.add(:file, "É obrigatório anexar um CV em PDF")
      render :new, status: :unprocessable_entity and return
    end

    if @analysis.save
      @analysis.file.attach(params[:analysis][:file])

      begin
        @analysis.cv_text = PdfParser.extract(@analysis.file)
        @analysis.save
      rescue PdfParserError => e
        @analysis.errors.add(:file, e.message)
        render :new, status: :unprocessable_entity and return
      end

      redirect_to analysis_path(@analysis), notice: "CV enviado! A IA está a analisar o teu perfil."
    else
      render :new, status: :unprocessable_entity
    end
  end
  private

  # Filtra os parâmetros permitidos vindos do formulário
  # :cv_text — texto do CV colado/digitado pelo user
  # :file    — ficheiro PDF do CV (Active Storage)
  def analysis_params
    params.require(:analysis).permit(:cv_text, :file)
  end
end
