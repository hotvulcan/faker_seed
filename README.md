# faker_seed

faker_seed is the easiest way to generate random seed data for your Rails models, it automatically creates random data based on the tables column names, trying to guess the best faker generator to be used in each one, this allows you to generate any number of random records for any model without configuring anything.

Include on your Gemfile:

    gem 'faker_seed'

Then, bundle install and run:

    rails g fake MODEL

This will generate a random fake record for the desired model. To generate more fake records run:

    rails g fake MODEL -n 50

It will generate 50 fake records on the database.

If it was too much, and you want to destroy 30, run:

    rails d fake MODEL -n 30

The code will also generate fake records for any model related to the main model through a has_many association, and will choose a random record on the belongs_to associations that the model may have.

It's also already integrated with paperclip, so it will download a random image from placeimg.com to save to the record if it has a paperclip attachment.

That's it, nice coding (: