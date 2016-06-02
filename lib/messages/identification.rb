class Identification

  def initialize(message)
    @message = message
    if !Identification.account_exists?(@message)
      @account = Account.new do |ac|
        ac.account_id = @message["accountId"]
        ac.stream = @message["stream"]
        ac.name = @message["name"]
        ac.status = @message["accountData"]["status"]
        ac.plan = @message["accountData"]["plan"]
      end
    else
      @account = Account.where(:stream => message["stream"],
                               :account_id => message["accountId"]).first
    end

    if !Identification.user_exists?(@message)
      @user = User.new do |u|
        u.stream = @message["stream"]
        u.user_id = @message["userId"]
        u.name = @message["userName"]
        u.role = @message["userData"]["role"]
        u.account = @account
      end
    else
      @user = User.where(:stream => message["stream"],
                         :user_id => message["userId"]).first

      if @user.account_id != @account.id
        puts "Error! User on multiple accounts! : #{@message}"
      end
    end
  end

  def save!
    @account.save! if !Identification.account_exists?(@message)
    @user.save! if !Identification.user_exists?(@message)
  end

  def self.account_exists?(message)
    !Account.where(:stream => message["stream"], :account_id => message["accountId"]).empty?
  end

  def self.user_exists?(message)
    !User.where(:stream => message["stream"], :user_id => message["userId"]).empty?
  end

end