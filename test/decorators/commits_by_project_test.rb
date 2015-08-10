require 'test_helper'
require 'test_helpers/commits_by_project_data'

class CommitsByProjectTest < ActiveSupport::TestCase
  let(:start_date_val) do
    (Time.current - 6.years).beginning_of_month
  end

  def start_date_str(month = 0)
    (Time.current - 6.years + month.months).beginning_of_month.strftime('%Y-%m-01 00:00:00')
  end

  let(:user) { create(:account) }

  let(:vita_fact) do
    vita = create(:best_vita, account_id: user.id)
    user.update(best_vita_id: vita.id)
    create(:vita_fact, vita_id: vita.id)
  end

  let(:position1) { create_position(account: user) }
  let(:position2) { create_position(account: user) }

  let(:construct_cbp_data) do
    cbp = CommitsByProjectData.new(position1.id, position2.id).construct
    vita_fact.update(commits_by_project: cbp)
  end

  before do
    construct_cbp_data
  end

  describe 'history' do
    it 'return commits by project data, start_date and max_commits count' do
      cbp_decorator = CommitsByProject.new(user)
      data = cbp_decorator.history
      data[:facts].size.must_equal 10
      data[:facts].first[:project_id].must_equal position1.project.id.to_s
      data[:facts].first[:month].to_s.must_equal start_date_str(1)
      data[:facts].first[:commits].must_equal '25'
      data[:start_date].to_s.must_equal (start_date_val.to_date + 1.month).to_s
      data[:max_commits].must_equal 40
    end

    it 'return commits by project data, start_date and max_commits count when commits_by_project is empty' do
      cbp_decorator = CommitsByProject.new(create(:admin))
      data = cbp_decorator.history

      data[:facts].must_equal []
      data[:start_date].must_equal Date.today.next_month.beginning_of_month
      data[:max_commits].must_equal 0
    end
  end

  describe 'history_in_date_range' do
    it 'return commits by project data when date range is specified' do
      start_date = (start_date_val + 4.months).to_date
      end_date = (start_date_val + 6.months).to_date
      cbp_decorator = CommitsByProject.new(user, context: { start_date: start_date, end_date: end_date })

      data = cbp_decorator.history_in_date_range

      data.size.must_equal 1
      project_data = data[position1.project.name]
      project_data.size.must_equal 3
      project_data.first[:month].to_s.must_equal((start_date_val + 4.months).to_date.to_s)
      project_data.first[:commits].must_equal 18
      project_data.first[:pname].must_equal position1.project.name
    end

    it 'return commits by project data when date range is not specified' do
      cbp_decorator = CommitsByProject.new(user)
      data = cbp_decorator.history_in_date_range

      data.size.must_equal 2
      project1_data = data[position1.project.name]
      project1_data.size.must_equal 85
      project1_data.first[:month].to_s.must_equal((start_date_val - 12.months).to_date.to_s)
      project1_data.first[:commits].must_equal nil
      project1_data.first[:pname].must_equal position1.project.name
    end
  end

  describe 'chart_data' do
    it 'return commits by project data for chart(x_axis, y_axis and max_commits)' do
      cbp_decorator = CommitsByProject.new(user)
      date_range = calculate_date_range(start_date_val.to_date, Date.today.beginning_of_month)

      chart_data = cbp_decorator.chart_data

      chart_data[:y_axis].must_equal [25, 40, 28, 18, 1, 8, 30, 12] + [0] * 64
      chart_data[:x_axis].must_equal date_range
      chart_data[:max_commits].must_equal 40
    end

    it 'return commits by project data for chart(x_axis, y_axis and max_commits) when project_id is given' do
      cbp_decorator = CommitsByProject.new(user)
      start_date = start_date_val.to_date
      end_date = Date.today.beginning_of_month
      date_range = calculate_date_range(start_date, end_date)

      chart_data = cbp_decorator.chart_data

      chart_data[:y_axis].must_equal [25, 40, 28, 18, 1, 8, 30, 12] + [0] * 64
      chart_data[:x_axis].must_equal date_range
      chart_data[:max_commits].must_equal 40
    end

    it 'return commits by project data for chart(x_axis, y_axis and max_commits) when commits_by_project is empty' do
      cbp_decorator = CommitsByProject.new(user)
      date_range = calculate_date_range(start_date_val.to_date, Date.today.beginning_of_month)

      chart_data = cbp_decorator.chart_data(position1.project.id)
      chart_data[:y_axis].must_equal [25, 40, 28, 18, 1, 8, 26, 9] + [0] * 64
      chart_data[:x_axis].must_equal date_range
      chart_data[:max_commits].must_equal 40
    end
  end

  def calculate_date_range(start_date, end_date)
    range = (start_date..end_date).map { |m| m.strftime('%b-%Y') }.uniq
    range = range - [range.first]
  end
end
