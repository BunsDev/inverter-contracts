// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IMilestone {
    //--------------------------------------------------------------------------------
    // Types

    struct Milestone {
        string title;
        uint startDate;
        string details;
        bool submitted;
        bool completed;
        bool removed;
    }

    //--------------------------------------------------------------------------------
    // Errors

    /// @dev This function is only callable by a contributor
    error OnlyCallableByContributor();

    /// @dev Invalid Title
    error InvalidTitle();

    /// @dev Invalid startDate
    error InvalidStartDate();

    /// @dev Invalid details
    error InvalidDetails();

    /// @dev There is no milestone with this id
    error InvalidMilestoneId();

    /// @dev The new Milestone Id is not yet available
    error NewMilestoneIdNotYetAvailable();

    /// @dev The Milestone with the given Id is already created
    error MilestoneWithIdAlreadyCreated();

    /// @dev The Milestone is not yet submitted
    error MilestoneNotSubmitted();

    /// @dev The Milestone is already completed
    error MilestoneAlreadyCompleted();

    /// @dev The Milestone is removed
    error MilestoneRemoved();

    //--------------------------------------------------------------------------------
    // Events

    /// @dev New Milestone was created
    event NewMilestone(string title, uint startDate, string details);

    /// @dev A Milestone was changed in regards of startDate or details
    event ChangeMilestone(uint id, uint startDate, string details);

    /// @dev A Milestone was changed in regards of startDate
    event ChangeStartDate(uint id, uint startDate);

    /// @dev A Milestone was changed in regards of details
    event ChangeDetails(uint id, string details);

    /// @notice A Milestone was removed
    event RemoveMilestone(uint id);

    /// @notice A Milestone was submitted
    event SubmitMilestone(uint id);

    /// @notice A submitted Milestone was confirmed
    event ConfirmMilestone(uint id);

    /// @notice A submitted Milestone was declined
    event DeclineMilestone(uint id);
}