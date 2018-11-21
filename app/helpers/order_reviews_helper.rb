module OrderReviewsHelper

  def reviewer_icon(review)
    if review.reviewer_type == 'SalesRep'
      user_icon
    else
      office_review_icon
    end
  end

  def reviewer_title(review)
    if review.reviewer_type == 'SalesRep'
      #review.reviewer.display_name
    else
      review.reviewer.name
    end
  end

  def order_review_overall(review, include_average = false)
    return "" unless review
    rating = review.overall
    return "" unless rating
    html = '<fieldset class="order-rating rating-disabled d-inline">'
    5.downto(1) do |i|
      i = i.to_s
      if rating.to_i == i.to_i
        html += '<input type="radio" id="reviewer_' + Time.now.to_f.to_s + '_' + i + '" name="reviewer_' + Time.now.to_f.to_s + '_' + i + '" value="' + i + '"checked/><label for="quality' + i + '">' + i + ' stars</label>'
      else
        html += '<input type="radio" id="reviewer_' + Time.now.to_f.to_s + '_' + i + '" name="reviewer_' + Time.now.to_f.to_s + '_' + i + '" value="' + i + '"/><label for="quality' + i + '">' + i + ' stars</label>'
      end
    end
    html += '</fieldset>'
    if include_average
      html += '<a class="btn btn-link pr-0 pt-0 pl-1 ft-normal">(' + rating.to_f.to_s + ')</a>'
    end

    html.html_safe
  end

  def office_review_overall(review)
    return "" unless review
    rating = review.overall
    return "" unless rating
    html = '<fieldset class="rating-disabled d-inline">'
    5.downto(1) do |i|
      i = i.to_s
      if rating.to_i == i.to_i
        html += '<input type="radio" id="reviewer_' + Time.now.to_f.to_s + '_' + i + '" name="reviewer_' + Time.now.to_f.to_s + '_' + i + '" value="' + i + '"checked/><label for="quality' + i + '">' + i + ' stars</label>'
      else
        html += '<input type="radio" id="reviewer_' + Time.now.to_f.to_s + '_' + i + '" name="reviewer_' + Time.now.to_f.to_s + '_' + i + '" value="' + i + '"/><label for="quality' + i + '">' + i + ' stars</label>'
      end
    end
    html += '</fieldset>'

    html.html_safe
  end

  def order_review_field(review, type)
    return "" unless review
    if type == :food_quality
      rating = review.food_quality
    elsif type == :presentation
      rating = review.presentation
    elsif type == :completion
      rating = review.completion
    elsif type == :overall
      rating = review.overall
    end
    return "" unless rating
    html = '<fieldset class="order-rating rating-disabled d-inline">'
    5.downto(1) do |i|
      i = i.to_s
      if rating.to_i == i.to_i
        html += '<input type="radio" id="review_' + review.id.to_s + '_' + type.to_s + i + '" name="review_' + review.id.to_s + '_' + type.to_s + i + '" value="' + i + '"checked/><label for="quality' + i + '">' + i + ' stars</label>'
      else
        html += '<input type="radio" id="review_' + review.id.to_s + '_' + type.to_s + i + '" name="review_' + review.id.to_s + '_' + type.to_s + i + '" value="' + i + '"/><label for="quality' + i + '">' + i + ' stars</label>'
      end
    end
    html += '</fieldset>'

    html.html_safe
  end

  def review_restaurant_name(review)
    OrderReview.find(review).order.restaurant_name
  end

  def review_order_number(order)
    Order.find(order).order_number
  end 

end
