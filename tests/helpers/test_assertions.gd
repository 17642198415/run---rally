extends RefCounted

var failures: Array[String] = []

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s Expected <%s>, got <%s>" % [message, str(expected), str(actual)])

func finish() -> int:
	if failures.is_empty():
		print("PASS: all tests passed")
		return 0

	for failure in failures:
		push_error(failure)
	return 1
