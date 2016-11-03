package com.example.andlua;

import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;

import org.keplerproject.luajava.LuaState;

import android.os.Environment;
import android.util.Log;

public abstract class LuaServerThread extends Thread {
	private static final String TAG = "AndLuaTAG";
	private LuaState L;
	private int port = 3333;
	private boolean stopped = false;
	
	public abstract void onLoadString(final PrintWriter out, final String code);

	public LuaServerThread(LuaState L) {
		this.L = L;
	}

	public LuaServerThread(LuaState L, int port) {
		this.L = L;
		this.port = port;
	}

	public void quit() {
		this.stopped = true;
	}

	@Override
	public void run() {
		try {
			ServerSocket server = new ServerSocket(port);
			Log.d(TAG, "Server started on port " + port);
			while (!stopped) {
				Socket client = server.accept();
				BufferedReader in = new BufferedReader(new InputStreamReader(
						client.getInputStream()));
				final PrintWriter out = new PrintWriter(
						client.getOutputStream());
				String line = null;

				StringBuffer code = new StringBuffer();
				while (!stopped && (line = in.readLine()) != null) {
					final String s = line.replace('\001', '\n');
					if (s.startsWith("--mod:")) {
						int i1 = s.indexOf(':'), i2 = s.indexOf('\n');
						String mod = s.substring(i1 + 1, i2);
						String file = Environment.getExternalStorageDirectory()
								.toString()
								+ "/"
								+ mod.replace('.', '/')
								+ ".lua";
						FileWriter fw = new FileWriter(file);
						fw.write(s);
						fw.close();
						L.getGlobal("package");
						L.getField(-1, "loaded");
						L.pushNil();
						L.setField(-2, mod);
						out.println("wrote " + file + "\n");
						out.flush();
					} else if (s.startsWith("--remote:")) {
						code.setLength(0);
						code.append('\n');
						while (!stopped && (line = in.readLine()) != null) {
							if (line.endsWith("--<eof>")) {
								onLoadString(out, code.toString());
								code.setLength(0);
								break;
							} else {
								code.append(line).append('\n');
							}
						}
					} else {
						Log.d(TAG, "onLoadString");
						onLoadString(out, s);
					}
				}
			}
			server.close();
		} catch (Exception e) {
			Log.e(TAG, e.toString());
		}
	}
}