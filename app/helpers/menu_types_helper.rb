module MenuTypesHelper

  def image_url(source)
    "mailto:username@example.com?subject=Subject&body=message%20goes%20here&attach="+ URI.join(root_url, image_path(source)).to_s
  end
end
