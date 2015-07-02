Darkswarm.factory 'Enterprises', (enterprises, CurrentHub, Taxons, Dereferencer, visibleFilter, Geo)->
  new class Enterprises
    enterprises_by_id: {}
    constructor: ->
      # Populate Enterprises.enterprises from json in page.
      @enterprises = enterprises
      # Map enterprises to id/object pairs for lookup.
      for enterprise in enterprises
        @enterprises_by_id[enterprise.id] = enterprise
      # Replace enterprise and taxons ids with actual objects.
      @dereferenceEnterprises()
      @dereferenceTaxons()
      @visible_enterprises = visibleFilter @enterprises
      @producers = @visible_enterprises.filter (enterprise)->
        enterprise.category in ["producer_hub", "producer_shop", "producer"]
      @hubs = @visible_enterprises.filter (enterprise)->
        enterprise.category in ["hub", "hub_profile", "producer_hub", "producer_shop"]

    dereferenceEnterprises: ->
      if CurrentHub.hub?.id
        CurrentHub.hub = @enterprises_by_id[CurrentHub.hub.id]
      for enterprise in @enterprises
        Dereferencer.dereference enterprise.hubs, @enterprises_by_id
        Dereferencer.dereference enterprise.producers, @enterprises_by_id

    dereferenceTaxons: ->
      for enterprise in @enterprises
        Dereferencer.dereference enterprise.taxons, Taxons.taxons_by_id
        Dereferencer.dereference enterprise.supplied_taxons, Taxons.taxons_by_id

    updateDistance: (query) ->
      if query?.length > 0
        @calculateDistance(query)
      else
        @resetDistance()

    calculateDistance: (query) ->
      Geo.geocode query, (results, status) =>
        if status == Geo.OK
          console.log "Geocoded #{query} -> #{results[0].geometry.location}."
          @setDistanceFrom results[0].geometry.location
        else
          console.log "Geocoding failed for the following reason: #{status}"
          @resetDistance()

    setDistanceFrom: (location) ->
      for enterprise in @enterprises
        enterprise.distance = Geo.distanceBetween enterprise, location

    resetDistance: ->
      enterprise.distance = null for enterprise in @enterprises
