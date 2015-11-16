module WithTeaser
  def teaser(more_link)

    index = description.index(/[.\n]/)
    if (index != nil)
      description[0,index]
    else
      description.truncate(70 + more_link.length, omission: ' '+more_link)
    end
  end
end
