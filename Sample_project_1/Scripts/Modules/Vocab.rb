# -*- coding: utf-8 -*-
#==============================================================================
# ** Vocab
#------------------------------------------------------------------------------
#  This module defines terms and messages. It defines some data as constant
# variables. Terms in the database are obtained from $data_system.
#==============================================================================

module Vocab

  # Écran d'un magasin
  ShopBuy         = "Acheter"
  ShopSell        = "Vendre"
  ShopCancel      = "Annuler"
  Possession      = "En possession"

  # Écran de statut
  ExpTotal        = "Exp. totale"
  ExpNext         = "%s suivant"

  # Écran de sauvegarde et chargement
  SaveMessage     = "Sauvegarder dans quel fichier ?"
  LoadMessage     = "Charger quelle partie ?"
  File            = "Fichier"

  # Affiché quand il y a plusieurs membres dans l'équipe
  PartyName       = "Équipe de %s"

  # Messages de combat généraux
  Emerge          = "%s apparaît !"
  Preemptive      = "%s a pris l'avantage!"
  Surprise        = "%s s'est fait surprendre !"
  EscapeStart     = "%s fuit !"
  EscapeFailure   = "La tentative de fuite a échoué !"

  # Messages de fin de combat
  Victory         = "%s a gagné !"
  Defeat          = "%s a perdu..."
  ObtainExp       = "%s points d'expérience reçus !"
  ObtainGold      = "%s\\G trouvés !"
  ObtainItem      = "%s trouvé !"
  LevelUp         = "%s est maintenant %s %s!"
  ObtainSkill     = "%s appris !"

  # Message affiché lors de l'utilisation d'un objet
  UseItem         = "%s utilise %s!"

  # Coup critique
  CriticalToEnemy = "Un joli coup !"
  CriticalToActor = "Un coup douloureux !"

  # Résultats des actions sur les personnages
  ActorDamage     = "%s a reçu %s dégâts !"
  ActorRecovery   = "%s a récupéré %s %s!"
  ActorGain       = "%s gagne %s %s!"
  ActorLoss       = "%s perd %s %s!"
  ActorDrain      = "%s a été drainé de %s %s!"
  ActorNoDamage   = "%s n'a rien senti !"
  ActorNoHit      = "Raté ! %s n'a pris aucun dégât !"

  # Résultats des actions sur les ennemis
  EnemyDamage     = "%s a reçu %s dégâts !"
  EnemyRecovery   = "%s a récupéré %s %s!"
  EnemyGain       = "%s gagne %s %s!"
  EnemyLoss       = "%s perd %s %s!"
  EnemyDrain      = "Drain de %s %s de %s!"
  EnemyNoDamage   = "%s n'a rien senti !"
  EnemyNoHit      = "Raté ! %s n'a pris aucun dégât !"

  # Esquive et contre-attaques
  Evasion         = "%s a esquivé l'attaque !"
  MagicEvasion    = "%s a contré la magie !"
  MagicReflection = "%s a renvoyé la magie !"
  CounterAttack   = "%s contre-attaque !"
  Substitute      = "%s protège %s !"

  # Renforcements et affaiblissements
  BuffAdd         = "%2$s de %1$s augmente !"
  DebuffAdd       = "%2$s de %1$s diminue !"
  BuffRemove      = "%2$s de %1$s est revenu à la normale."

  # Compétence ou objet qui n'a aucun effet
  ActionFailure   = "Aucun effet sur %s!"

  # Message d'erreur
  PlayerPosError  = "La position de départ de l'équipe n'est pas définie."
  EventOverflow   = "Nombre maximum d'appels d'évènement commun atteint."

  # Caractéristiques
  def self.basic(basic_id)
    $data_system.terms.basic[basic_id]
  end

  # Stats
  def self.param(param_id)
    $data_system.terms.params[param_id]
  end

  # Types d'équipements
  def self.etype(etype_id)
    $data_system.terms.etypes[etype_id]
  end

  # Commandes
  def self.command(command_id)
    $data_system.terms.commands[command_id]
  end

  # Unité monétaire
  def self.currency_unit
    $data_system.currency_unit
  end

  #--------------------------------------------------------------------------
  def self.level;       basic(0);     end   # Niveau
  def self.level_a;     basic(1);     end   # Niveau (abrégé
  def self.hp;          basic(2);     end   # PV
  def self.hp_a;        basic(3);     end   # PV (abrégé)
  def self.mp;          basic(4);     end   # PM
  def self.mp_a;        basic(5);     end   # PM (abrégé)
  def self.tp;          basic(6);     end   # PT
  def self.tp_a;        basic(7);     end   # PT (abrégé)
  def self.fight;       command(0);   end   # Combattre
  def self.escape;      command(1);   end   # Fuir
  def self.attack;      command(2);   end   # Attaquer
  def self.guard;       command(3);   end   # Se défendre
  def self.item;        command(4);   end   # Objets
  def self.skill;       command(5);   end   # Compétences
  def self.equip;       command(6);   end   # Équipement
  def self.status;      command(7);   end   # Statut
  def self.formation;   command(8);   end   # Formation
  def self.save;        command(9);   end   # Sauvegarder
  def self.game_end;    command(10);  end   # Quitter le jeu
  def self.weapon;      command(12);  end   # Armes
  def self.armor;       command(13);  end   # Armures
  def self.key_item;    command(14);  end   # Objets clés
  def self.equip2;      command(15);  end   # Changer équip.
  def self.optimize;    command(16);  end   # Optimiser
  def self.clear;       command(17);  end   # Tout enlever
  def self.new_game;    command(18);  end   # Nouvelle partie
  def self.continue;    command(19);  end   # Charger partie
  def self.shutdown;    command(20);  end   # Quitter
  def self.to_title;    command(21);  end   # Écran titre
  def self.cancel;      command(22);  end   # Annuler
  #--------------------------------------------------------------------------
end
