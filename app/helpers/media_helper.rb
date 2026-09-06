# Helper for media-related output, including lazy-loaded images.
module MediaHelper
  # Returns an image tag with lazy loading enabled by default.
  # Accepts the same arguments as `image_tag`.
  # Use this for images that are below the fold or not critical for LCP.
  def lazy_image_tag(source, options = {})
    options = options.reverse_merge(loading: "lazy")
    options[:class] = ((options[:class] || "").split + [ "lazy-skeleton" ]).join(" ").strip
    options[:onload] = "this.classList.remove('lazy-skeleton'); this.classList.add('lazy-loaded');"
    image_tag(source, options)
  end
end
