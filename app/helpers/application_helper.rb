module ApplicationHelper
  def title(page_title)
    content_for :title, page_title.to_s
    content_for :head, tag.meta(property: "og:title", content: page_title)
  end

  def canonical_url(url)
    content_for :head, tag.link(href: url, rel: "canonical")
    content_for :head, tag.meta(property: "og:url", content: url)
  end

  def meta_description(content)
    content_for :head, tag.meta(name: "description", content: content)
    content_for :head, tag.meta(property: "og:description", content: content)
  end

  def mdy(date)
    return unless date.present?
    date.to_date.strftime("%-m/%-d/%Y")
  end

  def github_url
    "https://github.com/toddwschneider/sec-13f-filings"
  end
end
