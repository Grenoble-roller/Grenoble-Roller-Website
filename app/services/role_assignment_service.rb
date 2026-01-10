# frozen_string_literal: true

# Service pour gérer l'assignation de rôles avec vérification de sécurité
# Un utilisateur ne peut jamais donner un rôle supérieur au sien
class RoleAssignmentService
  class UnauthorizedRoleAssignment < StandardError
    attr_reader :message

    def initialize(message = "Vous ne pouvez pas assigner un rôle supérieur au vôtre")
      @message = message
      super(message)
    end
  end

  # Vérifier si un utilisateur peut assigner un rôle donné à un autre utilisateur
  # @param assigner [User] L'utilisateur qui fait l'assignation
  # @param target_role [Role] Le rôle à assigner
  # @return [Boolean] true si l'assignation est autorisée
  def self.can_assign_role?(assigner:, target_role:)
    return false unless assigner&.role&.level
    return false unless target_role&.level

    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # Un utilisateur ne peut assigner que des rôles avec un level <= au sien
    assigner_level = assigner.role.level.to_i
    target_level = target_role.level.to_i

    target_level <= assigner_level
  end

  # Vérifier si un utilisateur peut assigner un rôle donné à un autre utilisateur
  # @param assigner [User] L'utilisateur qui fait l'assignation
  # @param target_user [User] L'utilisateur qui recevra le rôle
  # @param new_role [Role] Le nouveau rôle à assigner
  # @return [Boolean] true si l'assignation est autorisée
  def self.can_assign_role_to_user?(assigner:, target_user:, new_role:)
    return false unless assigner&.role&.level
    return false unless new_role&.level

    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # Un utilisateur ne peut assigner que des rôles avec un level <= au sien
    assigner_level = assigner.role.level.to_i
    new_role_level = new_role.level.to_i

    # Vérifier que le nouveau rôle n'est pas supérieur au rôle de l'assigneur
    return false if new_role_level > assigner_level

    # Si on modifie un utilisateur existant, vérifier aussi qu'on ne lui donne pas un rôle supérieur à celui qu'il avait déjà
    # (sauf si l'assigneur a un niveau supérieur à l'ancien rôle de la cible)
    if target_user&.persisted? && target_user.role&.level
      target_current_level = target_user.role.level.to_i
      # Si le nouveau rôle est supérieur à l'ancien, vérifier que l'assigneur a un niveau supérieur à l'ancien rôle
      if new_role_level > target_current_level
        return false unless assigner_level > target_current_level
      end
    end

    true
  end

  # Valider et assigner un rôle à un utilisateur
  # @param assigner [User] L'utilisateur qui fait l'assignation
  # @param target_user [User] L'utilisateur qui recevra le rôle
  # @param new_role [Role] Le nouveau rôle à assigner
  # @raise [UnauthorizedRoleAssignment] Si l'assignation n'est pas autorisée
  def self.assign_role!(assigner:, target_user:, new_role:)
    unless can_assign_role_to_user?(assigner: assigner, target_user: target_user, new_role: new_role)
      raise UnauthorizedRoleAssignment.new(
        "Vous ne pouvez pas assigner le rôle '#{new_role.name}' (level #{new_role.level}) " \
        "car votre niveau (#{assigner.role.level}) est insuffisant."
      )
    end

    target_user.role = new_role
  end
end
