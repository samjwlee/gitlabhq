require 'spec_helper'

describe ProjectsHelper do
  describe "#project_status_css_class" do
    it "returns appropriate class" do
      expect(project_status_css_class("started")).to eq("active")
      expect(project_status_css_class("failed")).to eq("danger")
      expect(project_status_css_class("finished")).to eq("success")
    end
  end

  describe "can_change_visibility_level?" do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:fork_project) { Projects::ForkService.new(project, user).execute }

    it "returns false if there are no appropriate permissions" do
      allow(helper).to receive(:can?) { false }

      expect(helper.can_change_visibility_level?(project, user)).to be_falsey
    end

    it "returns true if there are permissions and it is not fork" do
      allow(helper).to receive(:can?) { true }

      expect(helper.can_change_visibility_level?(project, user)).to be_truthy
    end

    context "forks" do
      it "returns false if there are permissions and origin project is PRIVATE" do
        allow(helper).to receive(:can?) { true }

        project.update visibility_level:  Gitlab::VisibilityLevel::PRIVATE

        expect(helper.can_change_visibility_level?(fork_project, user)).to be_falsey
      end

      it "returns true if there are permissions and origin project is INTERNAL" do
        allow(helper).to receive(:can?) { true }

        project.update visibility_level:  Gitlab::VisibilityLevel::INTERNAL

        expect(helper.can_change_visibility_level?(fork_project, user)).to be_truthy
      end
    end
  end

  describe 'user_max_access_in_project' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    before do
      project.team.add_user(user, Gitlab::Access::MASTER)
    end

    it { expect(helper.user_max_access_in_project(user.id, project)).to eq('Master') }
  end

  describe "readme_cache_key" do
    let(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    it "returns a valid cach key" do
      expect(helper.send(:readme_cache_key)).to eq("#{project.path_with_namespace}-#{project.commit.id}-readme")
    end

    it "returns a valid cache key if HEAD does not exist" do
      allow(project).to receive(:commit) { nil }

      expect(helper.send(:readme_cache_key)).to eq("#{project.path_with_namespace}-nil-readme")
    end
  end

  describe 'link_to_member' do
    let(:group)   { create(:group) }
    let(:project) { create(:empty_project, group: group) }
    let(:user)    { create(:user) }

    describe 'using the default options' do
      it 'returns an HTML link to the user' do
        link = helper.link_to_member(project, user)

        expect(link).to match(%r{/u/#{user.username}})
      end
    end
  end

  describe 'default_clone_protocol' do
    describe 'using HTTP' do
      it 'returns HTTP' do
        expect(helper).to receive(:current_user).and_return(nil)

        expect(helper.send(:default_clone_protocol)).to eq('http')
      end
    end

    describe 'using HTTPS' do
      it 'returns HTTPS' do
        allow(Gitlab.config.gitlab).to receive(:protocol).and_return('https')
        expect(helper).to receive(:current_user).and_return(nil)

        expect(helper.send(:default_clone_protocol)).to eq('https')
      end
    end
  end
end
