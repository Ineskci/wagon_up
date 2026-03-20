require "net/http"
require "json"

class ClaudeAnalyser
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

  def initialize(cv_text)
    @cv_text = cv_text
  end

  def call
    raw_json = call_api
    parse_response(raw_json)
  end

  private

  def call_api
    uri = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model: "claude-opus-4-5",
      max_tokens: 2000,
      messages: [{ role: "user", content: prompt }]
    }.to_json

    response = http.request(request)
    body = JSON.parse(response.body)
    puts "=== RESPOSTA DA API ==="
    puts body.inspect
    puts "======================"
    body.dig("content", 0, "text")
  end

  def prompt
    <<~PROMPT
      Analisa este CV e responde APENAS com JSON válido, sem texto adicional.

      CV:
      #{@cv_text}

      Responde com este formato exacto:
      {
        "summary": "resumo do perfil em 2-3 frases",
        "skills": ["skill1", "skill2", "skill3"],
        "roles": [
          {
            "title": "Nome do Cargo",
            "justification": "porque este cargo faz sentido para este perfil",
            "position": 1,
            "market_fit": {
              "brasil": { "salary": "R$ 8.000 - 12.000", "demand": "alta", "explanation": "..." },
              "portugal": { "salary": "€ 1.800 - 2.500", "demand": "media", "explanation": "..." },
              "internacional": { "salary": "$ 60k - 90k", "demand": "alta", "explanation": "..." }
            }
          },
          { "title": "...", "position": 2, "market_fit": {} },
          { "title": "...", "position": 3, "market_fit": {} }
        ]
      }
    PROMPT
  end

  def parse_response(raw_json)
    clean = raw_json.gsub(/```json|```/, "").strip
    JSON.parse(clean)
  rescue JSON::ParserError => e
    Rails.logger.error("ClaudeAnalyser JSON parse error: #{e.message}")
    fallback_response
  end

  def fallback_response
    {
      "summary" => "Erro ao processar o perfil. Tente novamente.",
      "skills" => [],
      "roles" => []
    }
  end

  def mock_response
    {
      "summary" => "Profissional com sólida experiência em marketing digital.",
      "skills" => ["SEO", "Google Ads", "Meta Ads", "Analytics"],
      "roles" => [
        {
          "title" => "Growth Marketing Manager",
          "justification" => "Perfil alinhado com estratégias de crescimento.",
          "position" => 1,
          "market_fit" => {
            "brasil" => { "salary" => "R$ 8.000 - 12.000", "demand" => "alta", "explanation" => "Mercado aquecido." },
            "portugal" => { "salary" => "€ 1.800 - 2.500", "demand" => "media", "explanation" => "Crescimento tech em Lisboa." },
            "internacional" => { "salary" => "$ 60k - 90k", "demand" => "alta", "explanation" => "Alta procura." }
          }
        },
        { "title" => "Digital Marketing Specialist", "justification" => "Experiência relevante.", "position" => 2, "market_fit" => {} },
        { "title" => "E-commerce Manager", "justification" => "Perfil adequado.", "position" => 3, "market_fit" => {} }
      ]
    }
  end
end
