# encoding: utf-8
require 'faker'
require 'brfaker'
I18n.reload!
class FakeGenerator < Rails::Generators::Base
	include ActionDispatch::TestProcess

	argument :table, :type => :string
	class_option :quant, :type => :string, :required => false, :aliases => "-n"

	def generate_fake

		@model = table.singularize.camelize.constantize
		quant = options["quant"] ? options["quant"].to_i : 1

		if behavior == :invoke
			total = 0
			quant.times do
				attributes = fake_attributes(@model)
				m = @model.new
				m.assign_attributes(attributes)
				m.save(validate: false)
				m.touch
				m.save
				total += 1
			end

			print "created, Created #{total} records on the table #{table.pluralize.camelize}"
			
		elsif behavior == :revoke
			total = 0
			@model.order('id DESC').limit(quant).each do |m|
				m.destroy
				total += 1
			end

			print "destroyed, Removed #{total} records from the table #{table.pluralize.camelize}"
		end
	end

	private
	def fake_attributes(model_class)
		attributes = {}
		model_class.columns.each do |column|
			name = column.name
			type = column.type
			next if name == "id" or name.include? "_id" or name == "created_at" or name == "updated_at"

			# Paperclip
			next if name.include?("_content_type") or name.include?("_file_size") or name.include?("_updated_at")
			if name.include?("_file_name")
				attachment = name.sub("_file_name", "")
				m = model_class.new
				if m.send(attachment).respond_to?('styles') # É um anexo
					styles = m.send(attachment).styles
					if styles.size > 0 # Foto
						max_num = 0
						width = 0
						height = 0
						styles.each do |key, style|
							size = style.geometry.sub(/[\^#>]/, '')
	          				area = size.split('x')[0].to_i * size.split('x')[1].to_i
							if area > max_num
            					max_num = area
            					width = size.split('x')[0].to_i
            					height = size.split('x')[1].to_i
            				end
						end
						puts "Downloading random image of size #{width}x#{height}"
						file = URI.parse("http://placeimg.com/#{width}/#{height}/any.jpg")
					else
						files = Dir.glob(Rails.root + 'lib/generators/fake/files/*')
						file = fixture_file_upload(files.sample, 'image/jpg')
					end
					attributes[attachment] = file
					next
				end
			end

			if type == :string
				if name.include?("name") or name.include?("nome")
					attributes[name] = Faker::Name.name
				elsif name.include?("email")
					attributes[name] = Faker::Internet.email
				elsif name.include?("link") or name.include?("url") or name.include?("site")
					attributes[name] = Faker::Internet.url
				elsif name.include?("phone") or name.include?("telephone") or name.include?("telefone") or name == "tel" or name == "cel" or name.include?("celular") or name.include?("cellphone")
					attributes[name] = Faker::PhoneNumber.phone_number
				elsif name.include?("cpf")
					attributes[name] = BrFaker::Cpf.cpf
				elsif name.include?("cnpj")
					attributes[name] = BrFaker::Cnpj.cnpj
				elsif name.include?("rua") or name.include?("logradouro") or name.include?("street") or name.include?("endereco") or name.include?("address")
					attributes[name] = Faker::Address.street_name
				elsif name.include?("bairro") or name.include?("district") or name.include?("area")
					attributes[name] = "Centro"
				elsif name == "cep"
					attributes[name] = Faker::Address.zip_code
				elsif name.include?("cidade") or name.include?("city")
					attributes[name] = Faker::Address.city
				elsif name.include?("estado") or name.include?("state")
					attributes[name] = Faker::Address.state
				elsif name == "sigla" or name.include?("state_abbr")
					attributes[name] = Faker::Address.state_abbr
				elsif name.include?("pais") or name.include?("country")
					attributes[name] = Faker::Address.country
				elsif name == "numero" or name.include?("number")
					attributes[name] = rand(1..300)
				elsif name == "complemento" or name.include?("complement")
					attributes[name] = rand() > 0.5 ? "Apto. 101" : ""
				elsif name == "lat" or name == "latitude"
					attributes[name] = Faker::Address.latitude
				elsif name == "lng" or name == "longitude"
					attributes[name] = Faker::Address.longitude
				elsif name == "sexo" or name == "gender"
					attributes[name] = (rand(0..1) == 0 ? "Male" : "Female")
				elsif name.include?("titulo") or name.include?("title")
					attributes[name] = Faker::Lorem.words(9).join(" ")
				else
					attributes[name] = Faker::Lorem.words(3).join(" ")
				end
			elsif type == :text
				attributes[name] = Faker::Lorem.words(30).join(" ")
			elsif type == :integer
				attributes[name] = rand(0..100)
			elsif type == :float
				if name == "lat" or name == "latitude"
					attributes[name] = Faker::Address.latitude
				elsif name == "lng" or name == "longitude"
					attributes[name] = Faker::Address.longitude
				else
					attributes[name] = ("%.2f" % rand(0.0..100.0)).to_f
				end
			elsif type == :datetime
				if name.include?("nasc") or name.include?("birth")
					attributes[name] = Time.now - rand(18..30).years - rand(1..12).months - rand(0..31).days
				elsif name == "de" or name.include?("_de") or name.include?("from")
					attributes[name] = Time.now - rand(0..100).days
				else
					attributes[name] = Time.now + rand(0..100).days
				end
			elsif type == :boolean
				attributes[name] = (rand(0..1) == 0 ? false : true)
			end
		end
		model_class.reflect_on_all_associations.each do |relation|
			if relation.macro == :belongs_to
				related_class_records = relation.class_name.constantize.all
				fk = relation.association_foreign_key
				m = model_class.new
				if related_class_records.size > 0 and m.respond_to?(fk)
					attributes[fk] = related_class_records.sample.id
				end
			elsif relation.macro == :has_many
				ids_str = relation.name.to_s.singularize + "_ids"
				if relation.options[:through] and model_class.accessible_attributes.include?(ids_str)
					related_class_records = relation.class_name.constantize.select('id').shuffle
					ids = related_class_records[0..[rand(0..5), related_class_records.size - 1].min]
					attributes[ids_str] = ids.collect {|c| c.id}

				elsif model_class.nested_attributes_options.include? relation.name.to_sym # accepts_nested_attributes_for
					relation_class = relation.class_name.constantize
					nested_attributes = {}
					for i in 0..rand(1..3) do
						nested_attributes[i.to_s] = fake_attributes(relation_class)
						nested_attributes[i.to_s].delete(model_class.name.downcase + "_id")
					end
					attributes[relation.name.to_s + "_attributes"] = nested_attributes
				end
			end
		end

		return attributes
	end

end
