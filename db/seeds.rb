puts "Limpando banco de dados..."
Answer.destroy_all
Interview.destroy_all
Role.destroy_all
Analysis.destroy_all
User.destroy_all

# ─── Users ────────────────────────────────────────────────────────────────────

puts "Criando usuários..."

ines = User.create!(
  name: "Inês Kaci",
  email: "ines@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

clara = User.create!(
  name: "Clara Mendes",
  email: "clara@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

rafaela = User.create!(
  name: "Rafaela Silva",
  email: "rafaela@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

gustavo = User.create!(
  name: "Gustavo Rocha",
  email: "gustavo@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

# ─── Analyses ─────────────────────────────────────────────────────────────────

puts "Criando análises..."

analysis_ines = Analysis.create!(
  user: ines,
  cv_text: "Formada em Marketing pela ESPM. Dois anos como analista de dados em startup de e-commerce. Participou do bootcamp de Data Science do Le Wagon em São Paulo.",
  summary: "Profissional com background em marketing em transição para dados. Combina visão de negócio com habilidades técnicas em análise e visualização.",
  skills: ["Python", "SQL", "pandas", "Power BI", "Google Analytics", "Excel", "storytelling com dados"]
)

analysis_clara = Analysis.create!(
  user: clara,
  cv_text: "Formada em Ciências da Computação pela USP. Três anos como desenvolvedora backend em fintech. Participou do bootcamp de Web Development do Le Wagon.",
  summary: "Desenvolvedora com sólida base técnica e experiência em sistemas financeiros. Busca transição para produto ou engenharia de dados.",
  skills: ["Ruby on Rails", "Python", "SQL", "APIs REST", "PostgreSQL", "Git", "metodologias ágeis"]
)

analysis_rafaela = Analysis.create!(
  user: rafaela,
  cv_text: "Formada em Administração pela FGV. Quatro anos em consultoria estratégica. Participou do bootcamp de Data Science do Le Wagon no Rio de Janeiro.",
  summary: "Consultora com forte pensamento analítico e experiência em projetos de transformação digital.",
  skills: ["Python", "SQL", "machine learning", "Excel avançado", "Power BI", "gestão de projetos"]
)

analysis_gustavo = Analysis.create!(
  user: gustavo,
  cv_text: "Formado em Design pela PUC-Rio. Cinco anos como UX Designer em agência digital. Participou do bootcamp de Web Development do Le Wagon em São Paulo.",
  summary: "Designer com foco em experiência do usuário e crescente interesse em desenvolvimento front-end.",
  skills: ["Figma", "HTML", "CSS", "JavaScript", "Ruby on Rails", "pesquisa com usuários", "prototipagem"]
)

# ─── Roles ────────────────────────────────────────────────────────────────────

puts "Criando roles..."

role_ines_1 = Role.create!(
  analysis: analysis_ines, position: 1, title: "Data Analyst",
  justification: "Seu background em marketing combinado com Python e SQL é o perfil ideal para analytics.",
  market_fit: { demand: "alta", avg_salary_brl: 7500, top_companies: ["iFood", "Nubank", "Mercado Livre"] }
)
Role.create!(
  analysis: analysis_ines, position: 2, title: "Growth Analyst",
  justification: "A combinação de marketing digital e análise de dados é o que times de growth precisam.",
  market_fit: { demand: "muito alta", avg_salary_brl: 8000, top_companies: ["Hotmart", "RD Station", "QuintoAndar"] }
)

role_clara_1 = Role.create!(
  analysis: analysis_clara, position: 1, title: "Engenheira de Dados",
  justification: "Sua base em computação e experiência com bancos de dados é o que times de engenharia de dados precisam.",
  market_fit: { demand: "muito alta", avg_salary_brl: 12000, top_companies: ["Nubank", "Itaú", "Stone"] }
)
Role.create!(
  analysis: analysis_clara, position: 2, title: "Product Engineer",
  justification: "Combina experiência técnica com visão de produto que vem do trabalho em fintech.",
  market_fit: { demand: "alta", avg_salary_brl: 11000, top_companies: ["Creditas", "Loft", "Vivo"] }
)

role_rafaela_1 = Role.create!(
  analysis: analysis_rafaela, position: 1, title: "Analytics Manager",
  justification: "Experiência em consultoria aliada a machine learning posiciona você para liderar times de dados.",
  market_fit: { demand: "alta", avg_salary_brl: 14000, top_companies: ["McKinsey", "Ambev", "Grupo Boticário"] }
)
Role.create!(
  analysis: analysis_rafaela, position: 2, title: "Data Scientist",
  justification: "Background quantitativo da FGV combinado com Python e ML é a base perfeita para ciência de dados.",
  market_fit: { demand: "alta", avg_salary_brl: 11000, top_companies: ["iFood", "Magazine Luiza", "BTG Pactual"] }
)

Role.create!(
  analysis: analysis_gustavo, position: 1, title: "UX Engineer",
  justification: "Combinação rara de design e desenvolvimento front-end para times que precisam fechar o gap design-dev.",
  market_fit: { demand: "muito alta", avg_salary_brl: 10000, top_companies: ["Figma", "Nubank", "Conta Azul"] }
)
Role.create!(
  analysis: analysis_gustavo, position: 2, title: "Product Designer",
  justification: "Experiência sólida em UX aliada ao entendimento técnico de desenvolvimento.",
  market_fit: { demand: "alta", avg_salary_brl: 9000, top_companies: ["Totvs", "RD Station", "PagSeguro"] }
)

# ─── Interviews ───────────────────────────────────────────────────────────────

puts "Criando entrevistas..."

interview_ines = Interview.create!(
  role: role_ines_1,
  category: "técnica",
  overall_score: 78,
  feedback_summary: "Boa comunicação e conhecimento de negócio. Precisa aprofundar SQL e praticar mais perguntas técnicas."
)

interview_clara = Interview.create!(
  role: role_clara_1,
  category: "técnica",
  overall_score: 85,
  feedback_summary: "Forte base técnica. Excelente raciocínio em queries complexas. Melhorar comunicação de soluções para não-técnicos."
)

interview_rafaela = Interview.create!(
  role: role_rafaela_1,
  category: "comportamental",
  overall_score: 91,
  feedback_summary: "Perfil muito sólido. Storytelling com dados excepcional. Pronta para liderar times."
)

# ─── Answers ──────────────────────────────────────────────────────────────────

puts "Criando respostas..."

# Inês
Answer.create!(
  interview: interview_ines,
  question: "Me fala sobre sua experiência com análise de dados.",
  answer: "Trabalhei 2 anos analisando dados de campanhas e comportamento de usuários. Usava Excel e Google Analytics no dia a dia. No Le Wagon aprendi Python e SQL para automatizar essas análises.",
  feedback: "Boa resposta com exemplos concretos. Poderia mencionar resultados quantitativos.",
  score: 8
)
Answer.create!(
  interview: interview_ines,
  question: "Como você faria uma query para encontrar os top 10 produtos mais vendidos no último mês?",
  answer: "SELECT product_id, COUNT(*) as total FROM orders WHERE created_at >= NOW() - INTERVAL '30 days' GROUP BY product_id ORDER BY total DESC LIMIT 10",
  feedback: "Query correta! Faltou considerar joins com a tabela de produtos para trazer o nome.",
  score: 7
)

# Clara
Answer.create!(
  interview: interview_clara,
  question: "Como você estruturaria um pipeline de dados para ingestão em tempo real?",
  answer: "Usaria Kafka para ingestão dos eventos, Spark Streaming para processar e transformar, e escreveria no data warehouse via Airflow para orquestração.",
  feedback: "Resposta muito completa. Demonstra conhecimento real de ferramentas de engenharia de dados.",
  score: 9
)
Answer.create!(
  interview: interview_clara,
  question: "Explica a diferença entre data lake e data warehouse.",
  answer: "Data lake armazena dados brutos em qualquer formato, é mais barato e flexível. Data warehouse armazena dados estruturados e transformados, optimizado para queries analíticas.",
  feedback: "Definição clara e correcta. Poderia dar exemplos de ferramentas para cada um.",
  score: 8
)

# Rafaela
Answer.create!(
  interview: interview_rafaela,
  question: "Como você apresentaria uma análise complexa para um CEO sem background técnico?",
  answer: "Começo sempre pelo 'so what' — qual decisão este dado vai ajudar a tomar. Depois mostro as 3 métricas mais importantes, sem jargão, com contexto histórico e uma recomendação clara.",
  feedback: "Excelente. Demonstra maturidade em comunicação executiva — ponto forte para Analytics Manager.",
  score: 10
)
Answer.create!(
  interview: interview_rafaela,
  question: "Descreve um momento em que os dados mudaram uma decisão estratégica.",
  answer: "Na consultoria, identificámos via análise de churn que clientes que não usavam o produto nas primeiras 2 semanas tinham 80% de probabilidade de cancelar. Isso mudou toda a estratégia de onboarding da empresa.",
  feedback: "Resposta impactante com dados concretos. Exatamente o que um entrevistador quer ouvir.",
  score: 10
)

# ─── Confirmação ──────────────────────────────────────────────────────────────

puts ""
puts "Seed concluído!"
puts "  #{User.count} usuários"
puts "  #{Analysis.count} análises"
puts "  #{Role.count} roles"
puts "  #{Interview.count} entrevistas"
puts "  #{Answer.count} respostas"
puts ""
puts "Logins (senha: 123456):"
User.all.each { |u| puts "  #{u.email}" }
