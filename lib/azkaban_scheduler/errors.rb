module AzkabanScheduler
  class AzkabanError < StandardError; end
  class AuthenticationError < AzkabanError; end
  class ProjectNotFoundError < AzkabanError; end
  class ProjectExistsError < AzkabanError; end
  class InvalidProjectNameError < AzkabanError; end
  class ProjectDescriptionEmptyError < AzkabanError; end
end
