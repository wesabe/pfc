= active-form plugin for Rails

active-form is a plugin that makes it easy to have model objects that support the 
ActiveRecord Validations but are not backed by database tables. The plugin is designed
to make it possible to use the ActiveForm derived classes in a very similar manner to
the ActiveRecord::Base derived objects.

Originally described at;

http://www.realityforge.org/articles/2005/12/02/validations-for-non-activerecord-model-objects

== How To Define An ActiveForm Object

class Search < ActiveForm
  attr_accessor :text
  validates_length_of :text, :maximum=>30
end

== How To Use ActiveForm Object In Controller

class NavigatorController < ApplicationController
  def search
    @search = Search.new(params[:search])
    if @search.valid?
      ...do search here...
    end
  end
end

== How To Use ActiveForm Object In View

<% form_tag(:action => 'search') %>
  <%= error_messages_for('search') %>
  <%= text_field('search', 'text', {"maxlength" => 30}) %>
  <button type="submit">Save</button>
<% end %>

== Details

License: Released under the MIT license.
Latest Version: http://www.realityforge.org/svn/public/code/active-form/trunk/

== Credits

Peter Donald <peter at realityforge dot org>.
Dae San Hwang for fix to work with Rails 1.1.
Trevor Squires for suggestion to use Reloadable::Subclasses rather than dispatcher hack for Rails 1.1.
Tim Lucas for patch to allow bulk addition of attributes.
Geoff Schmidt for adding support for Callbacks.