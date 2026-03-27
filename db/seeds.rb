puts "Limpando banco de dados..."
Answer.destroy_all
Interview.destroy_all
Role.destroy_all
Analysis.destroy_all
User.destroy_all


puts "Criando usuários..."

ines = User.create!(
  name: "Inês Kaci",
  email: "ines@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

clara = User.create!(
  name: "Clara Sato",
  email: "clara@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

rafaela = User.create!(
  name: "Rafaela Silva",
  email: "rafaela@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

gustavo = User.create!(
  name: "Gustavo Keoma",
  email: "gustavo@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

puts "Usuários criados: #{User.count}"

puts "Criando análise de Inês..."

ines_analysis = Analysis.create!(
  user:                  ines,
  status:                "completed",
  hard_skills_selected:  "Ruby on Rails, Ruby, JavaScript, PostgreSQL, HTML5, CSS3, Git, GitHub, Figma, Heroku",
  soft_skills_selected:  "Operations, Leadership, Problem Solving, Critical Thinking, Adaptability, Empathy, Curiosity, KPIs",
  target_markets:        "Brazil, Portugal, France",
  summary:               "Ines, your 7 years in operations aren't a liability — they're your edge. <strong>Most junior devs can code. Very few can also manage complex logistics at Olympic scale.</strong> That combination makes you unusually strong for ops-heavy product and engineering teams. Here's how I mapped your skills to the 3 roles where you'd stand out most.",
  cv_text:               "Ines Kaci — 7+ years in operations and logistics, including Paris 2024 Olympics. Le Wagon bootcamp graduate. Full-stack Rails developer.",
  raw_json:              { market_fit_score: 87 }
)

Role.create!(
  analysis: ines_analysis,
  title:    "Junior Full Stack Developer",
  position: 1,
  justification: "Production-ready Rails from day one, backed by 7 years of delivery.",
  market_fit: {
    "match_score"  => 87,
    "description"  => "Your Rails stack is production-ready from day one. And unlike most junior devs, you bring 7 years of real-world delivery — an edge most candidates can't fake.",
    "highlights"   => ["ruby-on-rails", "ruby", "javascript", "git", "operations", "leadership", "kpis"],
    "match_reasons" => [
      { "text" => "<strong>Ruby on Rails →</strong> fullstack ready from day one, no ramp-up needed",                        "green" => false },
      { "text" => "<strong>7 years operations →</strong> product sense and delivery rigour most junior devs lack",           "green" => false },
      { "text" => "<strong>Paris 2024 Olympics →</strong> proven execution under pressure at scale",                         "green" => true  }
    ]
  }
)

Role.create!(
  analysis: ines_analysis,
  title:    "Product Operations Specialist",
  position: 2,
  justification: "Build the tools you once had to request from engineers.",
  market_fit: {
    "match_score"  => 82,
    "description"  => "You've spent years optimising complex operations. Now you can build the tools you once had to request from engineers — a rare and powerful combination.",
    "highlights"   => ["operations", "leadership", "kpis", "critical-thinking", "javascript", "sql"],
    "match_reasons" => [
      { "text" => "<strong>Operations management →</strong> direct domain expertise, zero learning curve",                   "green" => true  },
      { "text" => "<strong>KPIs & data-driven decisions →</strong> product metrics are already your language",               "green" => true  },
      { "text" => "<strong>JavaScript + SQL →</strong> technical enough to build and query internal tools",                  "green" => false }
    ]
  }
)

Role.create!(
  analysis: ines_analysis,
  title:    "Technical Project Manager",
  position: 3,
  justification: "Technical credibility to bridge product and engineering teams.",
  market_fit: {
    "match_score"  => 79,
    "description"  => "You've led cross-functional teams at scale. Your new technical literacy gives you credibility with dev teams that most PMs don't have.",
    "highlights"   => ["leadership", "empathy", "problem-solving", "ruby-on-rails", "figma"],
    "match_reasons" => [
      { "text" => "<strong>Leadership + stakeholder management →</strong> core PM skills you already practise daily",        "green" => true  },
      { "text" => "<strong>Rails + Figma →</strong> technical credibility to bridge product and engineering",                "green" => false },
      { "text" => "<strong>Empathy + problem solving →</strong> team dynamics and conflict resolution at scale",             "green" => true  }
    ]
  }
)

puts "Análise de Inês criada com #{ines_analysis.roles.count} roles"
