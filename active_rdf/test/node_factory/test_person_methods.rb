# = test_person_methods.rb
#
# Unit Test of IdentifiedResource methods and accessors on Person type
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#

require 'test/unit'
require 'active_rdf'
require 'node_factory'
require 'test/node_factory/person'
require 'test/adapter/yars/manage_yars_db'
require 'test/adapter/redland/manage_redland_db'

DB = :yars
DB_HOST = 'opteron'
class TestNodeFactoryPerson < Test::Unit::TestCase

	def setup
		case DB
		when :yars
			setup_yars('test_create_person')
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_create_person' }
			@connection = NodeFactory.connection(params)
		when :redland
			setup_redland
			params = { :adapter => :redland }
			@connection = NodeFactory.connection(params)
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
	def teardown
		case DB
		when :yars
			delete_yars('test_create_person')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end

	def test_A_verify_literal_attributes
		person = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_equal('23', person['age'].value)
		assert_equal('renaud', person['name'].value)
		assert_equal('23', person.age)
		assert_equal('renaud', person.name)
	end
	
	def test_B_verify_resource_attributes
		person = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_7')
		other_person = person.knows
		assert_not_nil(other_person)
		assert_kind_of(Person, other_person)
		assert_equal('19', other_person['age'].value)
		assert_equal('audrey', other_person['name'].value)
		assert_equal('19', other_person.age)
		assert_equal('audrey', other_person.name)		

		renaud = other_person.knows
		assert_equal(renaud, person)
	end
	
	def test_C_verify_multiple_resource_attributes
		regis = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		other_persons = regis.knows
		assert_not_nil(other_persons)
		assert_kind_of(Array, other_persons)
		for person in other_persons
			assert_kind_of(Person, person)
		end
	end
	
	def test_D_modify_an_literal_attribute
		regis = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		new_age = Kernel.rand(50)
		regis.age = new_age
		new_regis = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		assert_equal(new_age.to_s, regis.age)
	end

#	def test_E_add_resource_attribute
#		regis = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_10')
#		renaud = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		
#		assert_not_nil(regis)
#		assert_not_nil(renaud)
#		assert_instance_of(Person, renaud.knows)
#		persons = [renaud.knows, regis]
#		renaud.knows = persons
#		
#	end
#	
#	def test_F_remove_literal_attribute
#	
#	end
#	
#	def test_G_remove_resource_attribute
#	
#	end
	
	def test_H_try_to_modify_uri
		eyal = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_8')
		eyal.uri = 'http://false_uri'
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_8', eyal.uri)
	end
	
	def test_I_create_and_delete_new_person
		new_person = Person.create('http://m3pe.org/activerdf/test/new_person')
		assert_not_nil(new_person)
		assert_instance_of(Person, new_person)
		new_person.name = 'new person'
		new_person.age = '20'
		new_person.delete
		assert(new_person.frozen?)
		assert_nil(NodeFactory.resources['http://m3pe.org/activerdf/test/new_person'])
	end
	
	def test_J_find_persons
		persons = Person.find
		assert_not_nil(persons)
		assert_equal(4, persons.size)
		for person in persons
			assert_instance_of(Person, person)
		end
	end
	
	def test_K_dynamic_find_method_on_person
		renaud = Person.find_by_name('renaud').first
		assert_not_nil(renaud)
		assert_instance_of(Person, renaud)
		assert_equal('renaud', renaud.name)
		assert_equal('23', renaud.age)
		assert_instance_of(Person, renaud.knows)
		
		renaud2 = Person.find_by_age('23').first
		assert_not_nil(renaud2)
		assert_instance_of(Person, renaud2)
		assert_equal(renaud, renaud2)
		
		renaud3 = Person.find_by_name_and_age('renaud', '23').first
		assert_not_nil(renaud3)
		assert_instance_of(Person, renaud3)
		assert_equal(renaud, renaud3)
	end
	
	def test_L_dynamic_find_method_with_resource_attribute_on_person
		audrey = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_9')
		persons = Person.find_by_knows(audrey)
		assert_not_nil(persons)
		assert_instance_of(Array, persons)
		for person in persons
			assert_instance_of(Person, person)
			assert_match(/(renaud|regis)/, person.name)
		end
	end
	
	def test_M_dynamic_find_method_with_multiple_resource_attributes_on_person
		audrey = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_9')
		renaud = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_7')
		regis = Person.find_by_knows([audrey, renaud]).first
		assert_not_nil(regis)
		assert_instance_of(Person, regis)
		assert_equal('regis', regis.name)
		persons = regis.knows
		assert_not_nil(persons)
		assert_instance_of(Array, persons)
		for person in persons
			assert_instance_of(Person, person)
			assert_block("Regis doesn't known the good person") {
				if person.object_id == audrey.object_id or person.object_id == renaud.object_id
					return true
				else
					return false
				end
			}
		end
	end	
end
