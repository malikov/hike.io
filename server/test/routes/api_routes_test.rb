require "rack/test"
require "test/unit"
require_relative "../test_case"
require_relative "../../model/database"
require_relative "../../routes/api_routes"

class ApiRoutesTest < HikeAppTestCase

	def setup
		clear_cookies
		header "Accept", "application/json"
		header "User-Agent", "rack/test (#{Rack::Test::VERSION})"
	end


	#
	# GET /api/v1/hikes
	#

	def test_get_hikes_ok
		get "/api/v1/hikes"
		assert last_response.ok?
	end

	def test_get_hikes_returns_multiple_hikes
		get "/api/v1/hikes"
		json = JSON.parse(last_response.body)
		assert json.length > 0
	end

	def test_get_hikes_with_fields_filter
		get "/api/v1/hikes?fields=name,string_id"
		json = JSON.parse(last_response.body)
		assert json[0]["name"] != nil
		assert json[0]["string_id"] != nil
		assert json[0]["description"] == nil
	end

	def test_get_hikes_includes_location
		get "/api/v1/hikes"
		json = JSON.parse(last_response.body)
		location = json[0]["location"]
		assert location != nil
		assert location["longitude"] != nil
		assert location["latitude"] != nil
	end

	def test_trailing_slash_doesnt_redirect
		get "/api/v1/hikes/"
		assert last_response.not_found?
	end


	#
	# GET /api/v1/hikes/search
	#

	def test_get_search_with_no_results
		get "/api/v1/hikes/search?q=not-a-real-hike"
		json = JSON.parse(last_response.body)
		assert_equal 200, last_response.status
		assert_equal 0, json.length
	end

	def test_get_search_with_one_result
		get "/api/v1/hikes/search?q=kilimanjaro"
		json = JSON.parse(last_response.body)
		assert_equal 200, last_response.status
		assert_equal 1, json.length
	end

	def test_get_search_with_two_results
		get "/api/v1/hikes/search?q=peak"
		json = JSON.parse(last_response.body)
		assert_equal 200, last_response.status
		assert_equal 2, json.length
	end

	def test_get_search_with_missing_query
		get "/api/v1/hikes/search"
		assert_equal 400, last_response.status
	end



	#
	# GET /api/v1/hikes/:id
	#
	def test_get_hike_by_id
		get "/api/v1/hikes/1"
		json = JSON.parse(last_response.body)
		assert_equal 1, json["id"]
	end

	def test_get_hike_by_string_id
		get "/api/v1/hikes/empty"
		json = JSON.parse(last_response.body)
		assert_equal "empty", json["string_id"]
	end

	def test_missing_hike
		get "/api/v1/hikes/not-a-real-hike"
		assert_equal 404, last_response.status
	end

	def test_get_hike_with_fields_filter
		get "/api/v1/hikes?fields=id,location"
		json = JSON.parse(last_response.body)
		assert json[0]["id"] != nil
		assert json[0]["location"] != nil
		assert json[0]["description"] == nil
	end


	#
	# POST /api/v1/hikes
	#

	def test_post_hike_without_credentials
		post "/api/v1/hikes", get_basic_hike_json.to_json
		assert_equal 202, last_response.status
	end

	def test_post_with_credentials
		data = get_basic_hike_json
		post_and_validate data, 200
		validate data, "new-name"
	end

	def test_post_without_input
		post_and_validate nil, 400
	end

	def test_post_hike_incomplete_input
		data = get_basic_hike_json
		data.delete("name")
		post_and_validate data, 400
	end

	def test_post_hike_invalid_distance
		data = get_basic_hike_json
		data["distance"] = "not-a-number"
		post_and_validate data, 400
	end

	def test_post_hike_invalid_elevation
		data = get_basic_hike_json
		data["elevation_max"] = "not-a-number"
		post_and_validate data, 400
	end

	def test_post_hike_invalid_latitude
		data = get_basic_hike_json
		data["location"]["latitude"] = 91
		post_and_validate data, 400
	end

	def test_post_hike_invalid_longitude
		data = get_basic_hike_json
		data["location"]["longitude"] = -181
		post_and_validate data, 400
	end

	def test_post_with_hike_that_already_exists
		data = get_basic_hike_json
		data["name"] = "Empty"
		post_and_validate data, 409
	end

	def test_post_hike_sets_keywords
		data = get_basic_hike_json
		data["name"] = "My new hike with unique keywords"
		post_and_validate data, 200
		get "/api/v1/hikes/search?q=unique+keywords"
		assert_equal JSON.parse(last_response.body).length, 1
	end


	#
	# PUT /api/v1/hikes/:id
	#

	def test_put_hike_without_credentials
		put "/api/v1/hikes/empty", get_basic_hike_json.to_json
		assert_equal 202, last_response.status
	end

	def test_put_hike_name
		put_and_validate get_basic_hike_json, 200
	end

	def test_put_hike_string_id
		data = get_basic_hike_json
		data["string_id"] = "new-hike"
		put_and_validate data, 200
	end

	def test_put_hike_string_id_conflicting
		data = get_basic_hike_json
		data["string_id"] = "scotchman-peak"
		put_and_validate data, 409
	end

	def test_put_invalid_distance
		data = get_basic_hike_json
		data["distance"] = "not-a-number"
		put_and_validate data, 400
	end

	def test_put_hike_invalid_latitude
		data = get_basic_hike_json
		data["location"]["latitude"] = -91
		put_and_validate data, 400
	end

	def test_put_to_missing_hike
		data = get_basic_hike_json
		data["string_id"] = "not-a-real-hike"
		put "/api/v1/hikes/not-a-real-hike", data.to_json
		assert_equal 404, last_response.status
	end


	#
	# DELETE /api/v1/hikes/:id
	#

	def test_delete_hike_without_credentials
		delete "/api/v1/hikes/empty"
		assert_equal 202, last_response.status
	end

	def test_delete_hike_with_credentials
		set_admin_cookie
		delete "/api/v1/hikes/scotchman-peak"
		assert_equal 200, last_response.status

		get "/api/v1/hikes/scotchman-peak"
		assert_equal 404, last_response.status
	end


	#
	# Helpers
	#

	def put_and_validate data, response_code
		set_admin_cookie
		put "/api/v1/hikes/empty", data.to_json
		if response_code == 200
			string_id = data["string_id"] || "empty"
			validate data, string_id
		else
			assert_equal response_code, last_response.status
		end
	end

	def post_and_validate data, response_code
		set_admin_cookie
		post "/api/v1/hikes", data.to_json
		assert_equal response_code, last_response.status
	end

	def validate data, hike_string_id
		json = JSON.parse(last_response.body)
		assert_equal hike_string_id, json["string_id"]
		validate_hashes data, json
		
		get "/api/v1/hikes/" + hike_string_id
		json = JSON.parse(last_response.body)
		assert_equal hike_string_id, json["string_id"]
		validate_hashes data, json
	end

	def validate_hashes expected_hash, actual_hash
		expected_hash.each do |key, value|
			if value.class == Hash
				validate_hashes value, actual_hash[key]
			else
				assert_equal value, actual_hash[key]
			end
		end
	end

end