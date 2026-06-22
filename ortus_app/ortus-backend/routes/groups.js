const express = require("express");
const { protect, authorizeRoles } = require("../middlewares/authMiddleware");
const {
  listGroups,
  trainerGroups,
  createGroup,
  confirmGroup,
  cancelGroup,
  getMembers,
  enroll,
  unenroll,
  myEnrollments,
} = require("../controllers/groupController");

const router = express.Router();

router.get("/", protect, authorizeRoles("client"), listGroups);
router.get("/my-enrollments", protect, authorizeRoles("client"), myEnrollments);
router.get("/trainer", protect, authorizeRoles("trainer"), trainerGroups);
router.post("/", protect, authorizeRoles("trainer"), createGroup);
router.patch("/:id/confirm", protect, authorizeRoles("trainer"), confirmGroup);
router.patch("/:id/cancel", protect, authorizeRoles("trainer"), cancelGroup);
router.get("/:id/members", protect, authorizeRoles("trainer"), getMembers);
router.post("/:id/enroll", protect, authorizeRoles("client"), enroll);
router.delete("/:id/enroll", protect, authorizeRoles("client"), unenroll);

module.exports = router;
