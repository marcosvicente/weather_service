Shoulda::Matchers.configure do |cfg|
  cfg.integrate do |with|
    with.test_framework :rspec
    with.library :rails

    with.library :active_record
    with.library :active_model
  end
end