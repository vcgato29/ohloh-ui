class BaseballCard < Draper::Decorator
  ROW_NAMES = [:first_checkin, :last_checkin, :commits, :joined_at, :contributions, :orgs, :affiliations]

  decorates :account
  delegate_all

  def initialize(*args)
    super
    @vita_fact = best_vita.try(:vita_fact)
    @language = most_experienced_language
    @organization_core = Account::OrganizationCore.new(object.id)
  end

  def rows
    ROW_NAMES.map { |row| send(row) }.compact.map { |row| row.reverse_merge(css: {}) }
  end

  private

  def first_checkin
    return if @vita_fact.blank? || @vita_fact.first_checkin.blank?
    { label: h.t('.first_checkin'),
      value: h.t('.duration', date: h.distance_of_time_in_words_to_now(@vita_fact.first_checkin)) }
  end

  def last_checkin
    return if @vita_fact.blank? || @vita_fact.last_checkin.blank?
    { label: h.t('.last_checkin'),
      value: h.t('.duration', date: h.distance_of_time_in_words_to_now(@vita_fact.last_checkin)) }
  end

  def commits
    return if best_vita.blank?
    { label: h.t('.commits.label'),
      value: h.t('.commits.value', count: @vita_fact.commits.to_i) }
  end

  def joined_at
    { label: h.t('.joined_at'),
      value: h.t('.duration', date: h.distance_of_time_in_words_to_now(created_at)) }
  end

  def contributions
    return if positions.count == 0
    link = h.link_to h.pluralize(positions.count, 'project'), h.account_positions_path(object)
    { label: h.t('.contibution'),
      value: link }
  end

  def orgs
    return if @organization_core.orgs_for_my_positions.empty?
    { css: { style: 'min-height:38px;' },
      label: h.t('.contibuted_to'),
      value: h.render(partial: 'accounts/show/orgs', locals: { orgs: orgs_for_positions }) }
  end

  def affiliations
    return if @organization_core.affiliations_for_my_positions.empty?
    { css: { style: 'min-height:38px;' },
      label: h.t('.contibuted_for'),
      value: h.render(partial: 'accounts/show/orgs', locals: { orgs: affiliated_orgs }) }
  end
end
