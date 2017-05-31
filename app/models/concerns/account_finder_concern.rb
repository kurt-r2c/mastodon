# frozen_string_literal: true

module AccountFinderConcern
  extend ActiveSupport::Concern

  class_methods do
    def find_local!(username)
      find_local(username) || raise(ActiveRecord::RecordNotFound)
    end

    def find_remote!(username, domain)
      find_remote(username, domain) || raise(ActiveRecord::RecordNotFound)
    end

    def find_local(username)
      find_remote(username, nil)
    end

    def find_remote(username, domain)
      AccountFinder.new(username, domain).account
    end
  end

  class AccountFinder
    attr_reader :username, :domain

    def initialize(username, domain)
      @username = username
      @domain = domain
    end

    def account
      scoped_accounts.take
    end

    private

    def scoped_accounts
      Account.unscoped.tap do |scope|
        scope.merge! matching_username
        scope.merge! matching_domain
      end
    end

    def matching_username
      raise(ActiveRecord::RecordNotFound) if username.blank?
      Account.where(Account.arel_table[:username].lower.eq username.downcase)
    end

    def matching_domain
      if domain.nil?
        Account.where(domain: nil)
      else
        Account.where(Account.arel_table[:domain].lower.eq domain.downcase)
      end
    end
  end
end