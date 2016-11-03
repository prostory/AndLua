package com.example.andlua;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.io.PrintWriter;

import org.keplerproject.luajava.JavaFunction;
import org.keplerproject.luajava.LuaException;
import org.keplerproject.luajava.LuaState;
import org.keplerproject.luajava.LuaStateFactory;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.ImageView.ScaleType;
import android.widget.TextView;

public class MainActivity extends Activity {
	private static final String TAG = "AndLuaTAG";
	public LuaState L;
	final StringBuilder output = new StringBuilder();
	private LuaServerThread luaServer = null;
	private Handler handler = new Handler();
	
	private static byte[] readAll(InputStream input) throws Exception {
		ByteArrayOutputStream output = new ByteArrayOutputStream(4096);
		byte[] buffer = new byte[4096];
		int n = 0;
		while (-1 != (n = input.read(buffer))) {
			output.write(buffer, 0, n);
		}
		return output.toByteArray();
	}
	
	private BroadcastReceiver receiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			restartActivity();
		}
	};

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		open();
		
		IntentFilter filter = new IntentFilter();
		filter.addAction("android_lua_refresh");
		registerReceiver(receiver, filter);
		if (luaServer == null) {
			luaServer = new LuaServerThread(L) {
				@Override
				public void onLoadString(final PrintWriter out, final String code) {
					handler.removeCallbacksAndMessages(null);
					handler.post(new Runnable() {
						@Override
						public void run() {
							long start = System.currentTimeMillis();
							String res = safeEvalLua(code);
							long time = System.currentTimeMillis() - start;
							if (res != null) {
								Log.d(TAG, "remote: " + res + ", execute in " + time + " ms");
								res = res.replace('\n', '\001');
								out.println(res);
								out.flush();
							}
						}
					});
				}
			};
			luaServer.start();
		}
	}
	
	@Override
	protected void onDestroy() {
		super.onDestroy();
		
		unregisterReceiver(receiver);
		
		if (luaServer != null) {
			luaServer.quit();
			luaServer = null;
		}
		
		close();
	}
	
	void restartActivity() {
		Intent intent = getIntent();
		overridePendingTransition(0, 0);
		finish();
		overridePendingTransition(0, 0);
		startActivity(intent);
	}
	
	void open() {
		L = LuaStateFactory.newLuaState();
		L.openLibs();

		try {
			L.pushJavaObject(this);
			L.setGlobal("activity");

			JavaFunction print = new JavaFunction(L) {
				@Override
				public int execute() throws LuaException {
					for (int i = 2; i <= L.getTop(); i++) {
						int type = L.type(i);
						String stype = L.typeName(type);
						String val = null;
						if (stype.equals("userdata")) {
							Object obj = L.toJavaObject(i);
							if (obj != null)
								val = obj.toString();
						} else if (stype.equals("boolean")) {
							val = L.toBoolean(i) ? "true" : "false";
						} else {
							val = L.toString(i);
						}
						if (val == null)
							val = stype;						
						output.append(val);
						output.append("\t");
					}
					output.append("\n");
					return 0;
				}
			};
			print.register("print");

			JavaFunction assetLoader = new JavaFunction(L) {
				@Override
				public int execute() throws LuaException {
					String name = L.toString(-1);

					AssetManager am = getAssets();
					try {
						InputStream is = am.open(name + ".lua");
						byte[] bytes = readAll(is);
						L.LloadBuffer(bytes, name);
						return 1;
					} catch (Exception e) {
						ByteArrayOutputStream os = new ByteArrayOutputStream();
						e.printStackTrace(new PrintStream(os));
						L.pushString("Cannot load module "+name+":\n"+os.toString());
						return 1;
					}
				}
			};
			
			L.getGlobal("package");            // package
			L.getField(-1, "loaders");         // package loaders
			int nLoaders = L.objLen(-1);       // package loaders
			
			L.pushJavaFunction(assetLoader);   // package loaders loader
			L.rawSetI(-2, nLoaders + 1);       // package loaders
			L.pop(1);                          // package
						
			L.getField(-1, "path");            // package path
			String customPath = Environment.getExternalStorageDirectory().toString() + "/?.lua";
			L.pushString(";" + customPath);    // package path custom
			L.concat(2);                       // package pathCustom
			L.setField(-2, "path");            // package
			
			L.getField(-1, "cpath");
			L.pushString(";" + getApplicationInfo().nativeLibraryDir + "/lib?.so");
			L.concat(2);
			L.setField(-2, "cpath");
			L.pop(1);
		} catch (Exception e) {
			Log.e(TAG, "Cannot override print");
		}
		
		try {
			String path = Environment.getExternalStorageDirectory().toString() + "/main.lua";
			String res = runLuaFile(path);
			Log.i(TAG, "result: " + res);
		} catch(LuaException e) {
			Log.e(TAG, e.getMessage()+"\n");
		}
	}
	
	void close() {
		if (L != null) {
			L.close();
			L = null;
		}
	}
	
	void reset() {
		close();
		open();
	}
	
	String safeRunLuaFile(String file) {
		String res = null;	
		try {
			String path = Environment.getExternalStorageDirectory().toString() + "/" + file;
			res = runLuaFile(path);
		} catch(Exception e) {
			res = e.getMessage()+"\n";
		}
		return res;
	}
	
	String runLuaFile(String file) throws LuaException {
		L.setTop(0);
		int ok = L.LloadFile(file);
		if (ok == 0) {
			L.getGlobal("debug");
			L.getField(-1, "traceback");
			L.remove(-2);
			L.insert(-2);
			ok = L.pcall(0, 0, -2);
			if (ok == 0) {				
				String res = output.toString();
				output.setLength(0);
				return res;
			}
		}
		throw new LuaException(errorReason(ok) + ": " + L.toString(-1));
	}
	
	String safeEvalLua(String src) {
		String res = null;
		try {
			res = evalLua(src);
		} catch (Exception e) {
			res = "--error: " + e.getMessage()+"\n";
		}
		return res;		
	}
	
	String evalLua(String src) throws LuaException {
		L.setTop(0);
		int ok = L.LloadString(src);
		if (ok == 0) {
			L.getGlobal("debug");
			L.getField(-1, "traceback");
			L.remove(-2);
			L.insert(-2);
			ok = L.pcall(0, 0, -2);
			if (ok == 0) {				
				String res = output.toString();
				output.setLength(0);
				return res;
			}
		}
		throw new LuaException(output.toString() + errorReason(ok) + ": " + L.toString(-1));
	}
	
	private String errorReason(int error) {
		switch (error) {
		case 6:
			return "IO error";
		case 4:
			return "Out of memory";
		case 3:
			return "Syntax error";
		case 2:
			return "Runtime error";
		case 1:
			return "Yield error";
		}
		return "Unknown error " + error;
	}
}
