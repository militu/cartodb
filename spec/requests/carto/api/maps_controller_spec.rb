# encoding: utf-8

require_relative '../../../spec_helper_min'
require 'support/helpers'
require_relative '../../../../app/controllers/carto/api/maps_controller'
require_relative '../../../../spec/requests/api/json/maps_controller_shared_examples'

describe Carto::Api::MapsController do
  include Carto::Factories::Visualizations, HelperMethods

  it_behaves_like 'maps controllers' do
  end

  def create_show_map_url(user: @user, map: @map)
    map_url(user_domain: user.subdomain, api_key: user.api_key, id: map.id)
  end

  describe '#update' do
    before(:all) do
      @user = FactoryGirl.create(:carto_user)
      @user2 = FactoryGirl.create(:carto_user)
      @map, @table, @table_visualization, @visualization = create_full_visualization(@user)
    end

    after(:all) do
      destroy_full_visualization(@map, @table, @table_visualization, @visualization)
      # This avoids connection leaking.
      ::User[@user.id].destroy
      ::User[@user2.id].destroy
    end

    let(:payload) do
      {
        bounding_box_ne: "[85.0511, 179]",
        bounding_box_sw: "[-85.0511, -179]",
        center: "[28.483177058570757, -82.825927734375]",
        legends: true,
        provider: "leaflet",
        scrollwheel: true,
        view_bounds_ne: "[32.30570601389429, -76.32202148437499]",
        view_bounds_sw: "[24.51713945052515, -89.329833984375]",
        zoom: 7,
        embed_options: {
          show_menu: false
        }
      }
    end

    it 'updates an existing map' do
      put_json create_show_map_url, payload do |response|
        response.status.should be_success
      end
    end

    it 'validates on update' do
      payload[:embed_options] = { spammy: 'hell', show_menu: true }
      put_json create_show_map_url, payload do |response|
        response.status.should eq 422
      end
    end

    it 'returns 401 for unathorized user' do
      put_json map_url(user_domain: @user2.subdomain,
                       api_key: 'wadus',
                       id: @map.id) do |response|
        response.status.should eq 401
      end
    end

    it 'returns 404 for maps not owned by the user' do
      put_json create_show_map_url(user: @user2) do |response|
        response.status.should eq 404
      end
    end

    it 'returns 404 for unexisting map' do
      put_json map_url(user_domain: @user.subdomain,
                       api_key: @user.api_key,
                       id: random_uuid) do |response|
        response.status.should eq 404
      end
    end
  end

  describe '#show' do
    before(:all) do
      @user = FactoryGirl.create(:carto_user)
      @user2 = FactoryGirl.create(:carto_user)
      @map, @table, @table_visualization, @visualization = create_full_visualization(@user)
    end

    after(:all) do
      destroy_full_visualization(@map, @table, @table_visualization, @visualization)
      # This avoids connection leaking.
      ::User[@user.id].destroy
      ::User[@user2.id].destroy
    end

    it 'returns an existing map' do
      get_json create_show_map_url do |response|
        response.status.should be_success
        response.body[:id].should eq @map.id
        response.body[:user_id].should eq @map.user_id
        response.body[:provider].should eq @map.provider
        response.body[:bounding_box_sw].should eq @map.bounding_box_sw
        response.body[:bounding_box_ne].should eq @map.bounding_box_ne
        response.body[:center].should eq @map.center
        response.body[:zoom].should eq @map.zoom
        response.body[:view_bounds_sw].should eq @map.view_bounds_sw
        response.body[:view_bounds_ne].should eq @map.view_bounds_ne
        response.body[:legends].should eq @map.legends
        response.body[:scrollwheel].should eq @map.scrollwheel
        response.body[:show_menu].should eq @map.show_menu
      end
    end

    it 'returns 401 for unathorized user' do
      get_json map_url(user_domain: @user2.subdomain,
                       api_key: 'wadus',
                       id: @map.id) do |response|
        response.status.should eq 401
      end
    end

    it 'returns 404 for maps not owned by the user' do
      get_json create_show_map_url(user: @user2) do |response|
        response.status.should eq 404
      end
    end

    it 'returns 404 for unexisting map' do
      get_json map_url(user_domain: @user.subdomain,
                       api_key: @user.api_key,
                       id: random_uuid) do |response|
        response.status.should eq 404
      end
    end
  end
end
