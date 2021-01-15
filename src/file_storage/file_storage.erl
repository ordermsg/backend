-module(file_storage).
-author("Order").
-license("MPL-2.0").
-description("File storage manager. Assumes ?STORAGE_PATH points to a distributed NFS like Gluster").

-define(STORAGE_PATH, "/data/brick1/gv0/").
-include_lib("cqerl/include/cqerl.hrl").
-record(file_info, { size, type, access }).

%% determines the file name by its ID
path_in_storage(Id) -> string:concat(?STORAGE_PATH, integer_to_list(Id)).

%% moves a file into the storage path and registers it in the DB
register_file(Path, Name) ->
    % read file info
    { ok, FileInfo } = file:read_file_info(Path),
    % generate an ID
    Id = utils:gen_snowflake(),
    % move it into the storage under the ID
    file:copy(Path, path_in_storage(Id)),
    file:delete(Path),
    % store it in the DB
    { ok, _ } = cqerl:run_query(get(cassandra), #cql_query{
        statement = "INSERT INTO blob_store (id, name, preview, pixel_size, length) VALUES (?, ?, ?, ?, ?)",
        values    = [
            { id,         Id },
            { name,       Name },
            { preview,    "" },
            { pixel_size, "" },
            { length, FileInfo#file_info.size }
        ]
    }),
    Id.