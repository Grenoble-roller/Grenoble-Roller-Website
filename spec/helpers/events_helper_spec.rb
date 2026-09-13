require 'rails_helper'

RSpec.describe EventsHelper, type: :helper do
  let(:creator) { create_user }
  let(:route1) { create_route(name: 'Boucle principale') }
  let(:route2) { create_route(name: 'Boucle secondaire', distance_km: 15.0) }

  describe '#format_event_distance' do
    it 'formats a single-loop event distance' do
      event = create_event(creator_user: creator, route: route1, distance_km: 10.0, loops_count: 1)

      expect(helper.format_event_distance(event)).to eq('10 km')
    end

    it 'joins per-loop distances instead of showing the total' do
      event = create_event(
        creator_user: creator,
        route: route1,
        loops_count: 2,
        distance_km: 5.0
      )
      event.event_loop_routes.create!(loop_number: 1, route: route1, distance_km: 5.0)
      event.event_loop_routes.create!(loop_number: 2, route: route2, distance_km: 7.0)

      expect(helper.format_event_distance(event)).to eq('5 km + 7 km')
      expect(helper.format_event_distance(event)).not_to include('12')
    end
  end

  describe '#route_difficulty_label' do
    it 'returns French labels' do
      expect(helper.route_difficulty_label('easy')).to eq('Facile')
      expect(helper.route_difficulty_label('medium')).to eq('Moyen')
      expect(helper.route_difficulty_label('hard')).to eq('Difficile')
    end
  end

  describe '#event_payment_mode_description' do
    it 'describes online payment when payment_required is true' do
      event = create_event(creator_user: creator, payment_required: true, price_cents: 500)

      expect(helper.event_payment_mode_description(event)).to include('panier')
    end

    it 'describes external payment when price is set but payment_required is false' do
      event = create_event(creator_user: creator, payment_required: false, price_cents: 500)

      expect(helper.event_payment_mode_description(event)).to include('organisateur')
    end
  end

  describe '#route_map_viewer_data' do
    it 'returns PhotoSwipe gallery item data when a map image is attached' do
      route = create_route
      route.map_image.attach(
        io: StringIO.new(DevLoopMapFixtures.build_map_png(loop_number: 1, color: '#2563eb')),
        filename: 'map.png',
        content_type: 'image/png'
      )

      data = helper.route_map_viewer_data(route, title: 'Boucle 1')

      expect(data[:controller]).to be_nil
      expect(data[:action]).to be_nil
      expect(data[:pswp_title]).to eq('Boucle 1')
    end
  end

  describe '#event_cover_viewer_data' do
    it 'returns PhotoSwipe gallery item data when a cover image is attached' do
      event = create_event(creator_user: creator)
      event.cover_image.attach(
        io: StringIO.new(DevLoopMapFixtures.build_map_png(loop_number: 1, color: '#dc2626')),
        filename: 'cover.png',
        content_type: 'image/png'
      )

      data = helper.event_cover_viewer_data(event)

      expect(data[:controller]).to be_nil
      expect(data[:pswp_title]).to eq(event.title)
    end
  end

  describe '#route_map_image_path' do
    it 'returns a resized representation for PNG attachments' do
      route = create_route
      route.map_image.attach(
        io: StringIO.new(DevLoopMapFixtures.build_map_png(loop_number: 1, color: '#2563eb')),
        filename: 'map.png',
        content_type: 'image/png'
      )

      expect(helper.route_map_image_path(route, resize_to: [ 800, 400 ])).to include('/rails/active_storage/representations/proxy/')
    end
  end

  describe '#event_loop_columns_class' do
    it 'returns responsive column classes' do
      expect(helper.event_loop_columns_class(2)).to eq('col-12 col-md-6')
      expect(helper.event_loop_columns_class(3)).to eq('col-12 col-md-4')
      expect(helper.event_loop_columns_class(4)).to eq('col-12 col-sm-6 col-xl-3')
    end
  end

  describe '#event_organizer_display' do
    it 'falls back to creator display name when no organizer is set' do
      event = create_event(creator_user: creator)

      expect(helper.event_organizer_display(event)).to eq(
        name: creator.display_name,
        url: nil
      )
    end

    it 'returns organizer name and safe url when organizer is set' do
      event_organizer = create(:event_organizer, name: 'Grenoble Roller', url: 'https://grenoble-roller.example')
      event = create_event(creator_user: creator, organizer: event_organizer)

      expect(helper.event_organizer_display(event)).to eq(
        name: 'Grenoble Roller',
        url: 'https://grenoble-roller.example'
      )
    end

    it 'sanitizes invalid organizer urls' do
      event_organizer = create(:event_organizer, url: 'https://example.com')
      event_organizer.update_column(:url, 'javascript:alert(1)')
      event = create_event(creator_user: creator, organizer: event_organizer)

      expect(helper.event_organizer_display(event)[:url]).to be_nil
    end
  end

  describe '#render_event_organizer' do
    it 'renders a plain span without url' do
      event = create_event(creator_user: creator)

      html = helper.render_event_organizer(event)

      expect(html).to include(creator.display_name)
      expect(html).not_to include('<a ')
    end

    it 'renders a link when organizer url is present' do
      event_organizer = create(:event_organizer, name: 'Grenoble Roller', url: 'https://grenoble-roller.example')
      event = create_event(creator_user: creator, organizer: event_organizer)

      html = helper.render_event_organizer(event)

      expect(html).to include('href="https://grenoble-roller.example"')
      expect(html).to include('target="_blank"')
      expect(html).to include('rel="noopener noreferrer"')
      expect(html).to include('Grenoble Roller')
    end
  end
end
