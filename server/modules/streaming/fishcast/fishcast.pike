/* PIKE */

/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2001 The Caudium Group
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#include <module.h>
inherit "module";
inherit "caudiumlib";

constant cvs_version = "$Id$";
constant version = "1.0a2";
constant thread_safe = 0; // maybe more like "constant will_kill_your_box_if_sneezed_at = 1;"
constant module_type = MODULE_LOCATION|MODULE_PARSER|MODULE_EXPERIMENTAL;
constant module_name = "Fishcast";
#if constant(thread_create)
constant module_doc =
    "<b>This is an streaming MP3 server for Caudium.</b><br>"
    "<i>Version: " + version + "</i><br><br>\n"
    "It supports Ice/Shoutcast streams and Audiocast streams.<br>\n"
    "It may have a 1.0 version number but that doesn't mean it's not "
    "going to crash your box, kill your goldfish, drink all your beer "
    "and sleep with your wife.<br>\n"
    "In short, your mileage may vary.\n";

#else
constant module_doc = "<font color=red><b>Your pike doesn't seem to have support for threads. That screws any chance of you running fishcast on this server!</font></b>";
#endif
constant module_unique = 1;

#define DEFAULT_METADATA_INTERVAL 4096
#define DEFAULT_UDP_PORT 8000

mapping streams = ([ ]);
mapping vars;

void create() {
    defvar( "location", "/fishcast/", "Mountpoint", TYPE_LOCATION, "The mountpoint in the virtual filesystem for this module" );
    defvar( "search_mp3", "/var/spool/mp3/", "Search Paths: MP3 Files", TYPE_STRING, "The path in the real filesystem to the MP3 directory" );
    defvar( "search_promo", "/var/spool/promo/", "Search Paths: Promo's", TYPE_STRING, "The path int the real filesystem to promo's if they are enabled", 0, promos_enable );
    defvar( "listing_streams", 0, "Listing: Stream Directory", TYPE_FLAG, "Enable listing of available streams", ({ "Yes", "No" }) );
    defvar( "listing_incoming", 0, "Listing: Incoming Directory", TYPE_FLAG, "Enable listing of available incoming streams", ({ "Yes", "No" }), incoming_enable );
    defvar( "listing_playlists", 0, "Listing: Playlist Directory", TYPE_FLAG, "Enable listing of available playlists", ({ "Yes", "No" }) );
    defvar( "maxclients", 20, "Clients: Maximum Clients", TYPE_INT, "Maximum connected clients (per stream). Zero is infinite (*very dangerous*)" );
    defvar( "sessiontimeout", 0, "Clients: Maximum Session Length", TYPE_INT, "Target client session length (in seconds). This option disconnects a client from a stream at the end of a track, once they have been on longer than this. If you have very long tracks it's not worth setting this at all." );
    defvar( "pauseplayback", 1, "Clients: Pause Playback", TYPE_FLAG, "Pause the &quot;playback&quot; of streams when there are no clients listening to them", ({ "Yes", "No" }) );
    defvar( "titlestreaming", 0, "Clients: Title Streaming", TYPE_FLAG, "Enable streaming of track titles to clients, this is known to cause issues with some MP3 players", ({ "Enabled", "Disabled" }) );
    defvar( "promos_enable", 0, "Promo's: Enable Promo's", TYPE_FLAG, "Enable Promo Streaming", ({ "Yes", "No" }) );
    defvar( "promos_freq", 10, "Promo's: Frequency", TYPE_INT, "Insert Promo into stream every how many tracks?", 0, promos_enable );
    defvar( "promos_shuffle", 0, "Promo's: Shuffle", TYPE_FLAG, "If selected then the Promo's will be randomly ordered, otherwise they will be ordered alphabetically", ({ "Yes", "No" }), promos_enable );
    defvar( "incoming_enable", 0, "Incoming Streams: Enable Incoming Streams", TYPE_FLAG, "Allow incoming stream connections?", 0 );
    defvar( "incoming_password", "changeme", "Incoming Streams: Password", TYPE_STRING, "Password for incoming streams", 0, incoming_enable );
}

int promos_enable() {
    return !QUERY(promos_enable);
}

int incoming_enable() {
    return !QUERY(incoming_enable);
}

void start( int cnt, object conf ) {
    if ( sizeof( streams ) > 0 ) {
#ifdef DEBUG
	perror( "Calling stop()...\n" );
#endif
	stop();
    }
    streams = ([ ]);
}

void stop() {
#ifdef DEBUG
    perror( "Forced module stop, terminating threads: " );
#endif
    if ( sizeof( streams ) > 0 ) {
	foreach( indices( streams ), int id ) {
	    streams[ id ]->terminate();
	}
    }
    streams = ([ ]);
#ifdef DEBUG
    perror( "done.\n" );
#endif
}

string status() {
    // I will deffinately do something here!
    if ( sizeof( streams ) == 0 ) {
        return "<b>No current streams</b>";
    }
    string ret =
	"<table border=1>\n";
    mixed sid;
    foreach( indices( streams ), sid ) {
	ret +=
	    "<tr><td colspan=2><b>Stream Name: " + (string)streams[ sid ]->meta->name + " (" + (string)streams[ sid ]->meta->current_track->title + ")</b></td><td><b>Read: " + (string)(int)(streams[ sid ]->meta->bytes / 1024 ) +  "kbytes (" + sprintf( "%:2f", (float)streams[ sid ]->meta->percent_played() ) + "%)</b></td></tr>\n";
        array clients = streams[ sid ]->list_clients();
	foreach( clients , object client ) {
	    ret +=
		"<tr><td>Client: " + (string)client->remoteaddr() + "</td>"
		"<td>Connected: " + (string)ctime( client->start_time() ) + "</td>"
		"<td>Sent: " + (string)( (int)client->bytes_written() / 1024 ) + "kbytes</td></tr>\n";
	}
    }
    ret += "</table>\n";
    return ret;
}

string query_location() {
    return QUERY(location);
}

mixed find_file( string path, object id ) {
    if ( path == "/" ) {
	return -1;
    } else if ( path == "" ) {
	return -1;
	// Root directory
    } else if ( path == "streams/" ) {
	return -1;
	// Streams directory
    } else if ( path == "playlists/" ) {
	return -1;
        // Playlists directory
    } else if ( path == "incoming/" ) {
	return -1;
	// Incoming streams directory
    } else {
	array parts = path / "/";
	parts = parts - ({ "" });
	if ( parts[ 0 ] == "streams" ) {
            // They want a stream!
	    int sid = (int)parts[ 1 ];
#ifdef DEBUG
	    perror( "Request for ID: " + (string)sid + "\n" );
#endif
	    if( streams[ sid ] ) {
#ifdef DEBUG
		perror( "Stream exists.\n" );
#endif
		id->my_fd->set_blocking();
#ifdef DEBUG
		perror( "done.\n" );
		perror( "Registering client to stream: " );
#endif
		streams[ sid ]->register_client( id );
#ifdef DEBUG
		perror( "done.\nReturning.\n" );
#endif
		return http_pipe_in_progress();
	    } else {
#ifdef DEBUG
		perror( "Stream doesnt exist.\n" );
#endif
		return 0;
	    }
	} else if ( parts[ 0 ] == "playlists" ) {
            // They want a playlist!
	    int sid = (int)replace( parts[ 1 ], ".pls", "" );
	    if ( streams[ sid ] ) {
		return http_string_answer(
					  "[playlist]\n"
					  "NumberOfEntries=1\n"
					  "File1=http://" + replace( id->host + "/" + QUERY(location) + "/streams/" + (string)sid, "//", "/" ) + "\n",
					  "audio/mpegurl" );
	    } else {
		return 0;
	    }
	} else if ( parts[ 0 ] == "incoming" ) {
            /*
	    // I havent even been able to test that this works yet
	    // mostly because last night when I was getting to it
	    // friends arrived and dragged us out to dinner :)
	    // If you feel like it, see if you can pipe a "live source"
	    // into the stream :)
	    if ( QUERY(incoming_enable) == 0 ) {
		return 0;
	    } else {
		int sid = (int)id->variables->sid;
		if ( streams[ sid ] ) {
		    // We dont want people streaming into existing streams!
		    return 0;
		} else {
		    if ( id->variables->password == QUERY(incoming_password) ) {
			mapping vars =
			    ([ "files" : ({ }),
			       "search_mp3" : "",
			       "loop" : 0,
			       "shuffle" : 0,
			       "bitrate" : id->vars->bitrate,
			       "maxclients" : QUERY(maxclients),
			       "maxsession" : QUERY(sessiontimeout),
			       "pause" : 0,
			       "name" : (id->variables->name?id->variables->name:id->remoteaddr),
			       "titlestreaming" : "Disabled",
			       "sid" : sid
			     ]);
			object s = stream( vars );
                        s->send_headers( id->my_fd );
                        thread_create( s->live_source, id->my_fd );
			streams += ([ sid : s ]);
                        return http_pipe_in_progress();
		    } else {
			return 0;
		    }
		}
		}
		*/
            return 0;
	}
    }
}

mixed find_dir( string path, object id ) {
    array parts = path / "/";
    parts = parts = ({ "" });
    if ( sizeof( parts ) == 0 ) {
	return ({ "streams", "playlists", "incoming" });
    } else if ( parts[ 0 ] == "streams" ) {
	if ( QUERY(listing_streams) ) {
	    array retval = ({ });
	    array tmp = indices( streams );
	    int sid;
	    foreach( tmp, sid ) {
		retval += ({ (string)sid });
	    }
	    return retval;
	} else {
	    return 0;
	}
    } else if ( parts[ 0 ] == "playlist" ) {
	if ( QUERY(listing_playlists) ) {
	    array retval = ({ });
	    array tmp = indices( streams );
            int sid;
	    foreach( tmp, sid ) {
		retval += ({ (string)sid + ".pls" });
	    }
	    return retval;
	} else {
	    return 0;
	}
    } else if ( parts[ 0 ] == "incoming" ) {
	return 0;
	// NOT IMPLEMENTED YET
    }
}

void|string real_file( string path, object id ) {
    return 0;
}

void|array stat_file( string path, object id ) {
    return 0;
}

mapping query_container_callers() {
    return ([ "stream":_tags_stream ]);
}

string _tags_stream( string tag, mapping args, string contents, object id ) {
    vars = ([ ]);
    if ( args->help ) {
	return #string "stream_help.html";
    }
    object meta = metadata();
    parse_html( contents, ([ ]), ([ "playlist" : _tags_playlist ]) );
    if ( sizeof( vars->playlist ) > 0 ) {
	foreach( indices( streams ), int _sid ) {
	    if ( streams[ _sid ]->meta->playlist - vars->playlist == ({ }) ) {
		vars += ([ "sid" : _sid ]);
	    }
	}
	if ( ! vars->sid ) {
	    meta->name = (args->name||"Unknown Stream");
	    meta->genre = args->genre;
	    meta->url = args->url;
	    meta->bitrate = args->bitrate;
	    meta->description = args->description;
	    meta->titlestreaming = QUERY(titlestreaming);
	    meta->live_source = 0;
	    meta->shuffle = vars->shuffle;
	    meta->loop = vars->loop;
	    meta->max_clients = QUERY(maxclients);
	    meta->max_session = QUERY(sessiontimeout);
	    meta->pause = QUERY(pauseplayback);
	    meta->search = QUERY(search_mp3);
	    if ( QUERY(promos_enable) ) {
		meta->promos_enable = 1;
		meta->promos_freq = QUERY(promos_freq);
		meta->promos_shuffle = QUERY(promos_shuffle);
		meta->promos_search = QUERY(search_promo);
	    }
            meta->playlist = vars->playlist;
	    object s = new_stream( meta );
	    vars->sid = s->get_ID();
	    streams += ([ s->get_ID() : s ]);
            thread_create( s->start );
	}
	if ( ! vars->sid ) {
	    return "<b>ERROR</b>: Failed to create new stream!";
	}
	if ( args->playlist ) {
	    return
		sprintf(
			"<a href='%s'>%s</a>",
			fix_relative( sprintf( "/" + QUERY(location) + "/playlists/%d.pls", vars->sid ), id ),
			"Listen to " + streams[ vars->sid ]->meta->name
		       );
	} else if ( args->stream_id ) {
	    return (string)vars->sid;
	}
    } else {
	return "Whatcyou talkin' 'bout Willis?";
    }
}

string _tags_playlist( string tag, mapping args, string contents ) {
    vars +=
	([ "playlist" : (contents / "\n") - ({ "" }) ]);
    if ( args->loop ) {
	vars +=
	    ([ "loop" : 1 ]);
    }
    if ( args->shuffle ) {
	vars +=
	    ([ "shuffle" : 1 ]);
    }
    return "";
}

class metadata {

    string name;
    string genre;
    string url;
    int streamid;
    int pub = 1;
    int bitrate;
    string description;
    int shuffle;
    int loop;
    int max_clients;
    int max_session;
    int pause;
    string search;
    int promos_enable;
    int promos_shuffle;
    int promos_freq;
    string promos_search;
    int titlestreaming;
    int default_metaint = 4096;
    int live_source = 0;
    int running;
    int bytes;
    array playlist;
    mapping current_track =
	([
	  "title" : 0,
	  "file_size" : 0,
	  "file_read" : 0
	 ]);

    mixed percent_played() {
	if ( live_source == 1 ) {
	    return -1;
	}
        return (float)current_track->file_read / (float)current_track->file_size;
    }

}

class stream_client {

    mapping vars =
	([
	  "protocol" : 0,
	  "start_time" : 0,
	  "unique_id" : 0,
	  "remoteaddr" : 0
	 ]);
    object id;
    object meta;
    object fd;
    int bytes = 0;

    void create( object _id, object _meta ) {
	id = _id;
	meta = _meta;
	fd = id->my_fd;
	// testing...
//        catch( fd->set_buffer( 0, "w" ) );
        // /testing
        vars->remoteaddr = id->remoteaddr;
	vars->start_time = time();
	vars->unique_id = time() * random( time() );
	if ( id->request_headers[ "icy-metadata" ] ) {
            vars->protocol = 1;
	} else if ( id->request_headers[ "x-audiocast-udpport" ] ) {
            vars->protocol = 2;
	} else {
            // Default protocol is ICY
            vars->protocol = 1;
	}
    }

    mixed client_write( string buff, void|string title ) {
	if ( ( meta->titlestreaming ) && ( title ) ) {
	    if ( protocol() == "ICY" ) {
		int i = bytes % meta->default_metaint;
		if ( i >= sizeof( buff ) ) {
		    bytes += sizeof( buff );
		    if ( fd->write( buff ) == -1 ) {
			return this_object();
		    }
		} else {
		    if ( i == 0 ) {
			if ( write_title( title ) == -1 ) {
			    return this_object();
			}
		    }
		    if ( fd->write( buff[ 0..i ] ) == -1 ) {
			return this_object();
		    }
		    if ( write_title( title ) == -1 ) {
			return this_object();
		    }
		    if ( fd->write( buff[ i..sizeof( buff ) ] ) == -1 ) {
                        return this_object();
		    }
		    bytes += sizeof( buff );
                    return 0;
		}
	    } else if ( ( protocol() == "Audiocast" ) && ( title ) ){
		if( fd->write( buff ) == -1 ) {
		    return this_object();
		}
                return 0;
	    }
	} else {
	    bytes += sizeof( buff );
	    if( fd->write( buff ) == -1 ) {
		return this_object();
	    }
            return 0;
	}
    }

    string remoteaddr() {
	return vars->remoteaddr;
    }

    int bytes_written() {
	return bytes;
    }

    int start_time() {
	return vars->start_time;
    }

    mixed protocol() {
	if ( vars->protocol == 1 ) {
	    return "ICY";
	} else if ( vars->protocol == 2 ) {
	    return "Audiocast";
	} else {
	    return 0;
	}
    }

    void write_headers() {
	string heads;
	if ( protocol() == "Audiocast" ) {
	    heads =
		"HTTP/1.0 200 OK\r\n"
		"Content-Type: audio/mpeg\r\n"
		"x-audiocast-genre:" + (meta->genre||"Unknown") + "\r\n"
		"x-audiocast-url:" + (meta->url||"http://www.caudium.net/") + "\r\n"
		"x-audiocast-name:" + meta->name + "\r\n"
		"x-audiocast-streamid:" + meta->id + "\r\n"
		"x-audiocast-public:" + meta->pub + "\r\n" +
		(meta->bitrate?"x-audiocast-bitrate:" + (meta->bitrate) + "\r\n":"") +
		"x-audiocast-description:Served by fishcast version 1.0\r\n";
	} else {
            // Default bahavior is icecast compatible mode.
	    heads =
		"ICY 200 OK\r\n"
		"Server: " + caudium.version() + "\r\n"
		"Content-Type: audio/mpeg\r\n" +
		(meta->titlestreaming?"icy-metaint:" + meta->default_metaint + "\r\n":"" ) +
		"icy-notice1:This stream requires a shoutcast compatible MP3 player.\r\n"
		"icy-notice2:Served by fishcast version 1.0\r\n"
		"icy-name:" + meta->name + "\r\n"
		"icy-genre:" + (meta->genre||"Unknown") + "\r\n"
		"icy-url:" + (meta->url||"http://www.caudium.net/") + "\r\n"
		"icy-pub:" + meta->pub + "\r\n" +
		(meta->bitrate?"icy-br:" + (string)meta->bitrate + "\r\n":"");
	}
        bytes += sizeof( heads );
	fd->write( heads );
    }

    int write_title( string title ) {
	if ( meta->titlestreaming ) {
	    if ( protocol() == "ICY" ) {
		string m = sprintf( " StreamTitle='%s';StreamUrl='%s';", title, meta->url );
		while( strlen( m ) & 15 ) m += "\0";
		m[ 0 ]=strlen( m )/16;
                bytes += sizeof( m );
		return fd->write( m );
	    } else if ( protocol() == "Audiocast" ) {
		// Do audiocast stuff
                return -1;
	    }
	}
    }

    void terminate() {
//	catch( fd->close() );
    }

}

class new_stream {

    array files;
    object meta;
    array clients;
    array write_callbacks;
    int ident;
    int delay_loop;
    string playing;
    int term;
    object fifo;
    int sending_to_clients;

    // Used to convert kilobytes per second to to bytes per 10th of a second.
    float scale = 12.8;

    void create( object _meta ) {
        meta = _meta;
	ident = (meta->sid?meta->sid:time() * random( time() ));
	clients = ({ });
	write_callbacks = ({ });
	fifo = Thread.Fifo();
    }

    int get_ID() {
	return ident;
    }

    void start() {
	// I am the actual reader thread
	meta->running = 1;
        meta->bytes = 0;
	int _loop = 1;
	int block = (int)( meta->bitrate * scale );
	delay_loop = time();
        array promos;
	if ( meta->promos_enable ) {
	    promos = sort( get_dir( meta->search_promo ) );
	}
	while( _loop == 1 ) {
	    _loop = meta->loop;
	    array files = (meta->shuffle?Array.shuffle(meta->playlist):meta->playlist);
	    int cnt = 1;
	    int promocnt;
	    string file;
	    array playlist = ({ });
	    foreach( files, file ) {
		if ( meta->promos_enable ) {
		    if ( cnt % meta->promos_freq == 0 ) {
			string p = (meta->promos_shuffle?promos[ random( sizeof( promos ) ) ]:promos[ promocnt ]);
			playlist += ({ Stdio.append_path( meta->search_promo, p ) });
			promocnt++;
		    }
		}
		playlist += ({ Stdio.append_path( meta->search, file ) });
		cnt++;
	    }
	    foreach( playlist, string filename ) {
		// Disconnect clients at the end of the last song once
		// they have used up their max session time, unless
                // maxsession = 0
		check_client_timeouts();
		object f;
		if ( catch( f = Stdio.File( filename, "r" ) ) ) {
#ifdef DEBUG
		    perror( "Can't locate file: " + meta->search + filename + "\n" );
#endif
                    continue;
		}
		int _bitrate = get_bitrate( f );
#ifdef DEBUG
		perror( "Bitrate: "  + (string)_bitrate + "\n" );
#endif
		if ( _bitrate == -1 ) {
#ifdef DEBUG
		    perror( "No SYNC in MPEG file!\n" );
#endif
                    continue;
		}
		if ( ( meta->bitrate > 0 ) && ( _bitrate != meta->bitrate ) ) {
		    // This means that we have been told to
		    // adhere to a specific bitrate, so skip
		    // this file.
#ifdef DEBUG
		    perror( "Skipping file, wrong bitrate!\n" );
#endif
		    continue;
		}
		block = (int)( _bitrate * 12.8 );
		playing = filename;
                meta->current_track->title = currently_playing( 1 );
//                song_change();
		meta->current_track->file_size = f->stat()[ 1 ];
                meta->current_track->file_read = 0;
#ifdef DEBUG
		perror( "Stream: " + meta->name + ", playing: " + playing + "\n" );
#endif
		if ( input( f, block, meta->current_track->title ) == -1 ) {
#ifdef DEBUG
		    perror( "Terminating Stream.\n" );
#endif
		    return;
		}
		f->close();
	    }
	}
	meta->running = 0;
    }

    void live_source( object f ) {
	// I am the reader thread if the source is live!
	meta->running = 1;
	meta->bytes = 0;
	string filename;
	int block = (int)( meta->bitrate * scale );
	delay_loop = time();
	if ( input( f, block ) == -1 ) {
#ifdef DEBUG
	    perror( "Terminating Stream.\n" );
#endif
	    return;
	}
	f->close();
	meta->running = 0;
    }

    int input( object f, int block, void|string title ) {
	string buff;
	int eof;
	float elapsed;
	while( eof == 0 ) {
	    elapsed = (float)time( delay_loop );
	    buff = f->read( block );
	    if ( buff == "" ) {
		eof = 1;
		break;
	    }
	    meta->bytes += block;
            meta->current_track->file_read += block;
	    // If there are no clients listening then you might as well
	    // wait until there are some.
		    // Does half a second between checks seem reasonable?
	    while( ( sizeof( clients ) == 0 ) && ( meta->pause == 1 ) ) {
		sleep( 0.5 );
	    }
	    if ( term == 1 ) {
#ifdef DEBUG
		perror( "Terminating thread.\n" );
#endif
		return -1;
	    }
	    //send( buff );
	    // I am not sure about this thread - should probably
	    // use thread_farm, however it seems to work, and has
	    // greatly improved performance, ie 25 client and only
	    // using 10% CPU on my PII 400!
	    fifo->write( ({ buff, title }) );
	    // this really needs to be changed so that if it takes
	    // longer than 1/10th of a second to send data to the clients
	    // then we are too busy, and should reduce samples to 9/second
	    // and increase the sample size. Or else maybe disconenct a client :)
	    sleep( ( 0.1 - ( (float)time( delay_loop ) - elapsed ) ) );
	}
        return 0;
    }

    void send_to_clients() {
        sending_to_clients = 1;
	while( term == 0 ) {
	    array buff = fifo->read();
	    if ( sizeof( clients ) > 0 ) {
		foreach( write_callbacks, function write ) {
		    mixed c = write( buff[ 0 ], buff[ 1 ] );
		    if ( ! intp( c ) ) {
			unregister_client( c );
		    }
		}
	    }
	}
#ifdef DEBUG
	perror( "Forced quit: closing sender thread!\n" );
#endif
	sending_to_clients = 0;
    }

    void check_client_timeouts() {
	if ( ( sizeof( clients )  > 0 ) && ( meta->max_session > 0 ) ) {
            int thyme = time();
	    foreach( clients, object client ) {
		if ( client->start_time() + meta->max_session > thyme ) {
		    unregister_client( client );
		}
	    }
	}
    }

    void register_client( object id ) {
#ifdef DEBUG
	perror( "Client " + id->remoteaddr + " connecting: " );
#endif
	if ( ( sizeof( clients ) == meta->max_clients ) && ( meta->max_clients > 0 ) ) {
#ifdef DEBUG
	    perror( "rejecting (maxclients).\n" );
#endif
	    id->my_fd->write(
		      "HTTP/1.1 502 Server Too Busy\n"
		      "Content-Type: text/html\n\n"
		      "<head>\n"
		      "<title>Server Too Busy</title>\n"
		      "<body>\n"
		      "I'm sorry, the maximum number of clients for this stream has been exceeded\n"
                      "</body>\n"
		     );
	    id->my_fd->close();
	} else {
	    object c = stream_client( id, meta );
	    c->write_headers();
	    clients += ({ c });
	    write_callbacks += ({ c->client_write });
	    if ( sending_to_clients == 0 ) {
                thread_create( send_to_clients );
	    }
	    if ( meta->running == 0 ) {
		thread_create( start );
	    }
#ifdef DEBUG
	    perror( "done.\n" );
#endif
	}
    }

    void unregister_client( object client ) {
	write_callbacks -= ({ client->client_write });
	client->terminate();
	clients -= ({ client });
    }

    array list_files() {
	return files;
    }

    void terminate() {
	term = 1;
	if ( sizeof( clients ) > 0 ) {
	    foreach( clients, object client ) {
#ifdef DEBUG
		perror( "Disconnecting client: " + client->remoteaddr() + "\n" );
#endif
		unregister_client( client );
	    }
	}
    }

    array list_clients() {
	return clients;
    }

    int sent_bytes() {
	return meta->bytes;
    }

    string currently_playing( void|int shorten ) {
	if ( shorten == 1 ) {
	    array path = playing / "/";
	    path -= ({ "" });
	    return replace( path[ sizeof( path ) - 1 ], ".mp3", "" );
	}
	return playing;
    }

    int get_bitrate( object f ) {
	object mh = mpeg( f );
        return mh->bitrate_of();
    }

}

class mpeg {
    /*
     * This class ported C->pike from mpeg.[c,h] from the icecast clients
     * package.
     * In turn ported from C++ in mp3info by slicer@bimbo.hive.no
     */


    mapping mh = ([
		   "lay" : 0,
		   "version" : 0,
		   "error_protection" : 0,
		   "bitrate_index" : 0,
		   "sampling_frequency" : 0,
		   "padding" : 0,
		   "extension" : 0,
		   "mode" : 0,
		   "mode_ext" : 0,
		   "copyright" : 0,
		   "original" : 0,
		   "emphasis" : 0,
		   "stereo" : 0,
		   "framesize" : 0,
		   "frametime" : 0
		  ]);

    array bitrate =
	({
		({
			({ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448 }),
			({ 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384 }),
			({ 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 })
		}),
		({
			({ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256 }),
			({ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 }),
			({ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 })
		}),
		({
			({ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256 }),
			({ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 }),
			({ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 })
		})
	});
    array s_freq =
	({
		({ 44100, 48000, 32000, 0 }),
		({ 22050, 24000, 16000, 0 }),
		({ 11025, 8000, 8000, 0 })
	});
    array mode_names = ({ "stereo", "j-stereo", "dual-ch", "single-ch", "multi-ch" });
    array layer_names = ({ "I", "II", "III" });
    array version_names = ({ "MPEG-1", "MPEG-2 LSF", "MPEG-2.5" });
    array version_nums = ({ "1", "2", "2.5" });
    int error;

    void create( object f ) {
	f->seek( 0 );
	string buff = f->read( 1024 );
	int readsize = sizeof( buff );
	readsize -= 4;
	if ( readsize <= 0 ) {
	    error = 1;
	    return;
	}
	string buffer;
        int temp;
        int count = 0;
	while( ( temp != 0xFFE ) && ( count <= readsize ) ) {
	    buffer = buff[ count..sizeof( buff ) ];
	    temp = ((buffer[ 0 ] << 4) & 0xFF0) | ((buffer[ 1 ] >> 4) & 0xE);
	    count++;
	}
	if ( temp != 0xFFE ) {
	    error = 1;
            return;
	} else {
	    switch((buffer[1] >> 3 & 0x3)) {
	    case 3:
		mh->version = 0;
                break;
	    case 2:
		mh->version = 1;
		break;
	    case 0:
		mh->version = 2;
		break;
	    default:
		error = 1;
                return;
		break;
	    }
	    mh->lay = 4 - ((buffer[1] >> 1) & 0x3);
	    mh->error_protection = !(buffer[1] & 0x1);
	    mh->bitrate_index = (buffer[2] >> 4) & 0x0F;
	    mh->sampling_frequency = (buffer[2] >> 2) & 0x3;
	    mh->padding = (buffer[2] >> 1) & 0x01;
	    mh->extension = buffer[2] & 0x01;
	    mh->mode = (buffer[3] >> 6) & 0x3;
	    mh->mode_ext = (buffer[3] >> 4) & 0x03;
	    mh->copyright = (buffer[3] >> 3) & 0x01;
	    mh->original = (buffer[3] >> 2) & 0x1;
	    mh->emphasis = (buffer[3]) & 0x3;
	    mh->stereo = (mh->mode == 3)?1:2;
	}
        f->seek( 0 );
    }

    int bitrate_of() {
        int _bitrate;
	if ( mixed err = catch( _bitrate = (error?-1:bitrate[ mh->version ][ mh->lay - 1 ][ mh->bitrate_index ]) ) ) {
	    return -1;
#ifdef DEBUG
	    perror( sprintf( "%O\n", err ) );
#endif
	} else {
	    return _bitrate;
	}
    }

}
