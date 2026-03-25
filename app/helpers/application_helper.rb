module ApplicationHelper
  # Generates a dynamic radar/spider chart SVG from a list of skill strings.
  # All confirmed skills are rendered at full score (the outer ring).
  def radar_chart_svg(skills)
    skills = Array(skills).reject(&:blank?).first(8)
    return "".html_safe if skills.empty?

    n = skills.length
    outer_r  = 78
    label_r  = 100
    grid_rs  = [27, 53, 78]

    grid_polygons = grid_rs.map do |r|
      pts = (0...n).map do |i|
        angle = (2 * Math::PI * i / n) - (Math::PI / 2)
        "#{(r * Math.cos(angle)).round(2)},#{(r * Math.sin(angle)).round(2)}"
      end.join(" ")
      %(<polygon points="#{pts}" fill="none" stroke="#E4E4E7" stroke-width="1"/>)
    end

    axes = (0...n).map do |i|
      angle = (2 * Math::PI * i / n) - (Math::PI / 2)
      x = (outer_r * Math.cos(angle)).round(2)
      y = (outer_r * Math.sin(angle)).round(2)
      %(<line x1="0" y1="0" x2="#{x}" y2="#{y}" stroke="#E4E4E7" stroke-width="0.5"/>)
    end

    skill_pts = (0...n).map do |i|
      angle = (2 * Math::PI * i / n) - (Math::PI / 2)
      "#{(outer_r * Math.cos(angle)).round(2)},#{(outer_r * Math.sin(angle)).round(2)}"
    end.join(" ")

    labels = skills.each_with_index.map do |skill, i|
      angle = (2 * Math::PI * i / n) - (Math::PI / 2)
      x = (label_r * Math.cos(angle)).round(2)
      y = (label_r * Math.sin(angle)).round(2)
      anchor = x.abs < 8 ? "middle" : (x > 0 ? "start" : "end")
      short = skill.length > 12 ? skill[0..11] + "…" : skill
      %(<text x="#{x}" y="#{y}" text-anchor="#{anchor}" dominant-baseline="middle" font-size="8" fill="#71717A">#{h(short)}</text>)
    end

    content_tag(:svg, viewBox: "-120 -120 240 240",
                style: "width:100%;max-width:240px;display:block;margin:0 auto 1.5rem") do
      raw([
        %(<defs><style>.rl{fill:none;stroke:#E4E4E7;stroke-width:1}.ra{fill:rgba(108,62,244,.15);stroke:#6C3EF4;stroke-width:1.5}</style></defs>),
        grid_polygons.join,
        axes.join,
        %(<polygon points="#{skill_pts}" class="ra"/>),
        labels.join
      ].join)
    end
  end
end
