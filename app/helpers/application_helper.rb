module ApplicationHelper
  def page_title
    content_for(:title) || "Bad Passwords"
  end

  def page_description
    content_for(:meta_description) || "Delegated password verification with remote Argon2 hashes, JWT issuance, and token validation."
  end

  def canonical_url
    request.original_url
  end

  def social_image_url
    image_url("preview.png")
  end
end
