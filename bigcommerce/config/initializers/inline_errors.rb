ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  unless html_tag =~ /^<label/
    %{#{html_tag}<span class="invalid_input"> #{instance.error_message.first}</span>}.html_safe
  else
    %{#{html_tag}}.html_safe
  end
end