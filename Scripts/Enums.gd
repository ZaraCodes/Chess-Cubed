class_name Enums

enum MessageType {
	PLAYER_EXISTS,
	PLAYER_COUNT_CHECK,
	ADD_PLAYER,
	WELCOME,
	JOIN_MESSAGE,
	CHAT_MESSAGE,
	GAME_STATE,
	MOVE,
	POSSIBLE_MOVES_REQUEST
}

enum AddPlayerResult {
	SUCCESS,
	MISSING_NAME,
	MISSING_ROLE,
	TOO_MANY_PLAYERS,
	ALREADY_EXISTS
}

enum PlayerRole {
	PLAYER,
	SPECTATOR
}

enum PlayerCountResult {
	VALID,
	TOO_MANY_PLAYERS,
	TOO_FEW_PLAYERS,
	MISSING_ROLE
}

enum ChatMessageResult {
	VALID,
	TEXT_MISSING,
	PLAYER_UNKNOWN
}

enum MoveType {
	SLICE,
	NORMAL,
	NONE
}

enum SliceAxis {
	X,
	Y,
	Z
}

enum Face {
	XUP,
	XDOWN,
	YUP,
	YDOWN,
	ZUP,
	ZDOWN
}
