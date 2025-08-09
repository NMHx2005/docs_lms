/**
 * LMS Database Initialization Script (MongoDB / mongosh)
 *
 * Usage:
 *   mongosh "<MONGODB_URI>/<DB_NAME>" document_database/init_db.js
 *   # or specify DB_NAME via env when connecting without db in URI
 *   DB_NAME=lms mongosh "<MONGODB_URI>" document_database/init_db.js
 *
 * Idempotent: Safe to re-run multiple times.
 */

(function () {
  // Polyfill for Compass Shell environments where tojson is not defined
  // eslint-disable-next-line no-var
  if (typeof tojson === 'undefined') {
    // eslint-disable-next-line no-var
    var tojson = function (v) {
      try { return JSON.stringify(v); } catch (_) { return String(v); }
    };
  }

  const dbName = (typeof process !== 'undefined' && process.env && process.env.DB_NAME)
    ? process.env.DB_NAME
    : (typeof db !== 'undefined' ? db.getName() : 'lms');

  const database = (typeof db !== 'undefined' && db.getName && db.getName() !== dbName)
    ? db.getSiblingDB(dbName)
    : db;

  if (!database || !database.getName) {
    throw new Error('Cannot resolve target database context');
  }

  function log(msg) { print(`[init-db] ${msg}`); }

  function ensureIndexes(collName, specs) {
    const coll = database.getCollection(collName);
    specs.forEach((spec) => {
      const { keys, options } = spec;
      const res = coll.createIndex(keys, options || {});
      // Use polyfilled tojson/JSON.stringify for logging in Compass
      log(`  - ${collName}.createIndex(${tojson(keys)}, ${tojson(options || {})}) => ${res}`);
    });
  }

  log(`Target DB: ${database.getName()}`);

  // Collections list (created implicitly by createIndex)
  const collections = [
    'users',
    'courses',
    'sections',
    'lessons',
    'assignments',
    'submissions',
    'enrollments',
    'bills',
    'refund_requests',
    'course_ratings'
  ];

  // Ensure collections exist at least lazily
  collections.forEach((name) => database.getCollection(name).insertOne({ __bootstrap__: true }) && database.getCollection(name).deleteOne({ __bootstrap__: true }));

  log('Creating indexes (users)');
  ensureIndexes('users', [
    { keys: { email: 1 }, options: { unique: true, name: 'uniq_user_email' } },
    { keys: { roles: 1 }, options: { name: 'idx_user_roles' } },
  ]);

  log('Creating indexes (courses)');
  ensureIndexes('courses', [
    // Filters + sort
    { keys: { isPublished: 1, isApproved: 1, domain: 1, level: 1, createdAt: -1 }, options: { name: 'idx_courses_filters_createdAt' } },
    // Featured
    { keys: { isPublished: 1, isApproved: 1, upvotes: -1, createdAt: -1 }, options: { name: 'idx_courses_featured' } },
    // Instructor and common filters
    { keys: { instructorId: 1, isPublished: 1, isApproved: 1 }, options: { name: 'idx_course_instructor_publish_approve' } },
    { keys: { domain: 1 }, options: { name: 'idx_course_domain' } },
    { keys: { level: 1 }, options: { name: 'idx_course_level' } },
    // Text search (VN-friendly)
    { keys: { title: 'text', description: 'text' }, options: { name: 'txt_course_title_description', default_language: 'none' } },
  ]);

  log('Creating indexes (sections)');
  ensureIndexes('sections', [
    { keys: { courseId: 1, order: 1 }, options: { unique: true, name: 'uniq_section_order_in_course' } },
    { keys: { courseId: 1 }, options: { name: 'idx_sections_by_course' } },
  ]);

  log('Creating indexes (lessons)');
  ensureIndexes('lessons', [
    { keys: { sectionId: 1, order: 1 }, options: { unique: true, name: 'uniq_lesson_order_in_section' } },
    { keys: { sectionId: 1 }, options: { name: 'idx_lessons_by_section' } },
    { keys: { type: 1 }, options: { name: 'idx_lessons_by_type' } },
  ]);

  log('Creating indexes (assignments)');
  ensureIndexes('assignments', [
    { keys: { lessonId: 1 }, options: { name: 'idx_assignments_by_lesson' } },
    { keys: { dueDate: 1 }, options: { name: 'idx_assignments_dueDate' } },
  ]);

  log('Creating indexes (submissions)');
  ensureIndexes('submissions', [
    { keys: { assignmentId: 1, submittedAt: -1 }, options: { name: 'idx_submissions_by_assignment' } },
    { keys: { assignmentId: 1, studentId: 1 }, options: { unique: true, name: 'uniq_submission_assignment_student' } },
  ]);

  log('Creating indexes (enrollments)');
  ensureIndexes('enrollments', [
    { keys: { studentId: 1, courseId: 1 }, options: { unique: true, name: 'uniq_enrollment_student_course' } },
    { keys: { studentId: 1, enrolledAt: -1 }, options: { name: 'idx_enrollments_by_student' } },
  ]);

  log('Creating indexes (bills)');
  ensureIndexes('bills', [
    { keys: { studentId: 1, paidAt: -1 }, options: { name: 'idx_bills_by_student' } },
    { keys: { courseId: 1, paidAt: -1 }, options: { name: 'idx_bills_by_course' } },
    { keys: { status: 1 }, options: { name: 'idx_bills_status' } },
    { keys: { purpose: 1 }, options: { name: 'idx_bills_purpose' } },
  ]);

  log('Creating indexes (refund_requests)');
  ensureIndexes('refund_requests', [
    { keys: { studentId: 1, requestedAt: -1 }, options: { name: 'idx_refunds_by_student' } },
    { keys: { courseId: 1, requestedAt: -1 }, options: { name: 'idx_refunds_by_course' } },
    { keys: { billId: 1 }, options: { name: 'idx_refunds_by_bill' } },
    { keys: { status: 1 }, options: { name: 'idx_refunds_status' } },
  ]);

  log('Creating indexes (course_ratings)');
  ensureIndexes('course_ratings', [
    { keys: { courseId: 1, type: 1 }, options: { name: 'idx_ratings_course_type' } },
    { keys: { studentId: 1, courseId: 1, type: 1 }, options: { unique: true, name: 'uniq_rating_student_course_type' } },
  ]);

  // Optional: TTL example for tokens collection (only if used)
  try {
    if (database.getCollectionNames().includes('tokens')) {
      log('Creating indexes (tokens - TTL)');
      ensureIndexes('tokens', [
        { keys: { expiresAt: 1 }, options: { expireAfterSeconds: 0, name: 'ttl_tokens_expiresAt' } },
      ]);
    }
  } catch (e) {
    log(`(optional) tokens TTL skipped: ${e.message}`);
  }

  // Optional cleanup of deprecated fields (example: courses.enrolledStudents)
  try {
    const deprecated = database.courses.updateMany(
      { enrolledStudents: { $exists: true } },
      { $unset: { enrolledStudents: '' } }
    );
    log(`Cleanup deprecated field courses.enrolledStudents => matched: ${deprecated.matchedCount || deprecated.nMatched}, modified: ${deprecated.modifiedCount || deprecated.nModified}`);
  } catch (e) {
    log(`Cleanup skipped: ${e.message}`);
  }

  log('Done.');
})();
