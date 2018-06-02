FactoryGirl.define do
  factory :user, class: User do
    name { "Жора_#{rand(999)}" }

    sequence(:email) { |n| "someguy_#{n}@example.com" }

    is_admin false
    balance 0

    after(:build) {|u| u.password_confirmation = u.password = "12345"}
  end
end