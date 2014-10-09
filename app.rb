#!/usr/bin/env ruby
require 'sinatra'
require 'json'
require 'fluent-logger'
require_relative 'lib/hash.rb'

ATTRIBUTION = 'public/img/attribution.json'

class PuppyChooser < Sinatra::Base
  enable :sessions
  enable :static

  set :session_secret, 'zomgcuteoverload'

  before '/' do
    session[:animals_used] ||= []
    session[:votes] ||= []
  end

  before '/reset' do
    logger.post('animals.events', { 'type' => 'reset' })
    session.clear
  end

  get '/' do
    puppy = candidate('puppies')
    kitten = candidate('kittens')
    unless puppy.nil? || kitten.nil?
      @p_name, @p_info = puppy.first, puppy.last
      @k_name, @k_info = kitten.first, kitten.last
      erb :animals
    else
      @results = results
      erb :results
    end
  end

  post '/result' do
    session[:votes] << params[:species]
    session[:animals_used].push(params[:puppy], params[:kitten])
    logger.post(
      'animals.events',
      {
        'type' => 'vote', 
        'species' => params[:species],
        'method' => params[:method],
      }
    )
  end

  get '/reset' do
    redirect '/'
  end

  helpers do
    def animals
      @animals ||= JSON.parse(File.read(ATTRIBUTION))
    end

    def filter_hash(hash)
      hash.reject { |a, _| session[:animals_used].include? a }
    end

    def candidate(species)
      filter_hash(animals[species]).shuffle.first
    end

    def results
      puppies = session[:votes].select { |n| n[/puppy/] }
      kittens = session[:votes].select { |n| n[/kitten/] }
      return { puppies: puppies.length, kittens: kittens.length }
    end

    def logger
      @logger ||= Fluent::Logger::FluentLogger.new(nil, :host=>'localhost', :port=>24224)
    end
  end
end
