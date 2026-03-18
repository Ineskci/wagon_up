class PagesController < ApplicationController
  # A página home é pública — não exige login
  skip_before_action :authenticate_user!, only: [:home]

  # GET /
  # Landing page pública da app
  # Não carrega dados — apenas apresenta o produto
  def home
  end

  # GET /dashboard
  # Painel do utilizador autenticado
  # @analyses  — todas as análises do user, da mais recente para a mais antiga
  # @interviews — todas as entrevistas do user, encontradas via JOIN:
  #               Interview → Role → Analysis → filtra pelo user_id do current_user
  def dashboard
    @analyses = current_user.analyses.order(created_at: :desc)
    @interviews = Interview.joins(role: :analysis)
                           .where(analyses: { user_id: current_user.id })
                           .order(created_at: :desc)
  end
end
