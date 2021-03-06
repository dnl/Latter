module ApplicationHelper

  def cache_key_for(object, scope = nil)
    [Latter::Application.config.version, object, scope].compact
  end

  def player_navigation
    render(:partial => 'layouts/navigation/player_navigation') if current_player
  end

  def anonymous_navigation
    render(:partial => 'layouts/navigation/anonymous_navigation') unless current_player
  end

end
