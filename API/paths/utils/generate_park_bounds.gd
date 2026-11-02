@tool
class_name GenerateParkBounds
extends EditorScript

func _run() -> void:
	var park_db_path = "res://API/theme_parks/resources/park_db.res"
	var park_db: ParkDB = load(park_db_path) as ParkDB
	
	if not park_db:
		print("[CRITICAL ERROR] Failed to load park_db.res! Check file path.")
		return

	var base_output_dir = "C:/Users/thoma/Documents/coding/coderen-5v-data/API/theme_parks/resources/"
	var parks_metadata = []

	for continent_key in park_db.parks_by_location:
		var zones = park_db.parks_by_location[continent_key]
		var region_keyword = _get_region_keyword(continent_key)
		
		for zone_key in zones:
			var parks = zones[zone_key]
			for park_key in parks:
				var park_res = parks[park_key]
				if not park_res or not "attractions" in park_res:
					continue
				
				var min_lon = INF
				var max_lon = -INF
				var min_lat = INF
				var max_lat = -INF
				
				var park_lat_fallback = 0.0
				var park_lon_fallback = 0.0
				if "latitude" in park_res: park_lat_fallback = park_res.latitude
				if "longitude" in park_res: park_lon_fallback = park_res.longitude

				var valid_attractions = 0
				for attraction in park_res.attractions:
					if attraction.longitude != 0.0 and attraction.latitude != 0.0:
						min_lon = min(min_lon, attraction.longitude)
						max_lon = max(max_lon, attraction.longitude)
						min_lat = min(min_lat, attraction.latitude)
						max_lat = max(max_lat, attraction.latitude)
						valid_attractions += 1

				if valid_attractions == 0:
					if park_lat_fallback != 0.0:
						min_lat = park_lat_fallback - 0.02
						max_lat = park_lat_fallback + 0.02
						min_lon = park_lon_fallback - 0.02
						max_lon = park_lon_fallback + 0.02
					else:
						continue
				else:
					var buffer = 0.025
					min_lat -= buffer
					max_lat += buffer
					min_lon -= buffer
					max_lon += buffer

				var folder_name = park_key
				for char in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
					folder_name = folder_name.replace(char, "")

				parks_metadata.append({
					"key_name": park_key,
					"folder_name": folder_name,
					"region_keyword": region_keyword,
					"min_lat": min_lat,
					"max_lat": max_lat,
					"min_lon": min_lon,
					"max_lon": max_lon
				})

	var python_script_content = _generate_python_batch_code(parks_metadata, base_output_dir)
	var file = FileAccess.open("C:/Users/thoma/Documents/coding/coderen-5v-data/API/theme_parks/resources/extract_all_parks.py", FileAccess.WRITE)
	file.store_string(python_script_content)
	file.close()

	print("Successfully generated bounds and corrected SQLite multi-core export script for ", parks_metadata.size(), " parks!")

func _get_region_keyword(continent_key: String) -> String:
	var lower_key = continent_key.to_lower()
	if "europe" in lower_key:
		return "europe-latest.osm(1).pbf"
	elif "asia" in lower_key:
		return "asia-261031.osm.pbf"
	elif "australia" in lower_key or "oceania" in lower_key:
		return "australia-oceania-261030.osm.pbf"
	elif "central" in lower_key:
		return "central-america-261030.osm.pbf"
	elif "africa" in lower_key:
		return "africa"
	else:
		return "north-america-latest.osm(1).pbf"

func _generate_python_batch_code(parks: Array, base_dir: String) -> String:
	var code = """import os
import glob
import json
import time
import sqlite3
import osmium
import multiprocessing

class NodeCollector(osmium.SimpleHandler):
	def __init__(self, db_path):
		super().__init__()
		self.conn = sqlite3.connect(db_path)
		self.cursor = self.conn.cursor()
		self.cursor.execute("PRAGMA journal_mode = WAL;")
		self.cursor.execute("PRAGMA synchronous = OFF;")
		self.cursor.execute("PRAGMA cache_size = -2000000;")
		self.cursor.execute("CREATE TABLE IF NOT EXISTS nodes (id INTEGER PRIMARY KEY, lat REAL, lon REAL)")
		self.conn.commit()
		self.batch = []

	def node(self, n):
		if n.location.valid():
			self.batch.append((n.id, n.location.lat, n.location.lon))
			if len(self.batch) >= 200000:
				self.cursor.executemany("INSERT OR REPLACE INTO nodes VALUES (?, ?, ?)", self.batch)
				self.conn.commit()
				self.batch = []

	def close(self):
		if self.batch:
			self.cursor.executemany("INSERT OR REPLACE INTO nodes VALUES (?, ?, ?)", self.batch)
			self.conn.commit()
		self.conn.close()

class WayExtractor(osmium.SimpleHandler):
	def __init__(self, parks_list, db_path):
		super().__init__()
		self.parks = parks_list
		for p in self.parks:
			p['extracted_ways'] = []
		self.conn = sqlite3.connect(db_path)
		self.cursor = self.conn.cursor()
		self.cursor.execute("PRAGMA journal_mode = WAL;")
		self.cursor.execute("PRAGMA synchronous = OFF;")
		self.cursor.execute("PRAGMA cache_size = -2000000;")

	def way(self, w):
		if "highway" in w.tags and w.tags["highway"] in ["footway", "path", "pedestrian"]:
			node_ids = [n.ref for n in w.nodes]
			if not node_ids:
				return
            
			placeholders = ','.join(['?'] * len(node_ids))
			self.cursor.execute(f"SELECT id, lat, lon FROM nodes WHERE id IN ({placeholders})", node_ids)
			node_map = {row[0]: (row[1], row[2]) for row in self.cursor.fetchall()}
            
			node_coords = []
			for nid in node_ids:
				if nid in node_map:
					node_coords.append(node_map[nid])
				else:
					if len(node_coords) > 1:
						self._process_segment(node_coords)
					node_coords = []
            
			if len(node_coords) > 1:
				self._process_segment(node_coords)

	def _process_segment(self, node_coords):
		for park in self.parks:
			current_segment = []
			for lat, lon in node_coords:
				if park['min_lat'] <= lat <= park['max_lat'] and park['min_lon'] <= lon <= park['max_lon']:
					current_segment.append([lat, lon])
				else:
					if len(current_segment) > 1:
						park['extracted_ways'].append(current_segment)
					current_segment = []
			if len(current_segment) > 1:
				park['extracted_ways'].append(current_segment)

	def close(self):
		self.conn.close()

def process_single_region(args):
	region_keyword, group_parks, base_dir, downloads_dir = args
	pattern = os.path.join(downloads_dir, region_keyword)
	matches = glob.glob(pattern)
    
	if not matches:
		print(f"[ERROR] PBF file NOT FOUND for pattern: {region_keyword} in {downloads_dir}")
		return False
        
	pbf_file = matches[0]
	print(f"\\n[INFO] Starting region: {region_keyword} ({len(group_parks)} parks target)")
    
	parks_to_process = []
	for park in group_parks:
		folder_path = os.path.join(base_dir, park["folder_name"])
		os.makedirs(folder_path, exist_ok=True)
		json_output_path = os.path.join(folder_path, "paths.json")
        
		if os.path.exists(json_output_path) and os.path.getsize(json_output_path) > 10:
			print(f"  [SKIPPED] '{park['key_name']}' (paths.json already exists)")
			continue
		parks_to_process.append(park)

	if not parks_to_process:
		print(f"  [INFO] All parks in region '{region_keyword}' already processed.")
		return True

	db_path = os.path.join(base_dir, f"nodes_{region_keyword}.db")
	start_time = time.time()
    
	try:
		print(f"  [PASS 1/2] Indexing nodes into SSD SQLite database...")
		collector = NodeCollector(db_path)
		collector.apply_file(pbf_file, locations=False)
		collector.close()
        
		print(f"  [PASS 2/2] Extracting paths for parks...")
		extractor = WayExtractor(parks_to_process, db_path)
		extractor.apply_file(pbf_file, locations=False)
		extractor.close()
        
		print(f"  [INFO] Region complete in {round(time.time() - start_time, 2)}s. Writing JSON...")
		for park in parks_to_process:
			folder_path = os.path.join(base_dir, park["folder_name"])
			json_output_path = os.path.join(folder_path, "paths.json")
            
			with open(json_output_path, "w") as f:
				json.dump(park['extracted_ways'], f)
			print(f"    -> Saved {len(park['extracted_ways'])} paths for '{park['key_name']}'")
            
	except Exception as e:
		print(f"\\n[CRITICAL ERROR] Failed processing region '{region_keyword}':\\n{str(e)}")
		return False
	finally:
		if os.path.exists(db_path):
			os.remove(db_path)
        
	return True

if __name__ == '__main__':
	parks_data = """
	code += JSON.stringify(parks, "\t")
	code += """

	BASE_DIR = r"%s"
	DOWNLOADS_DIR = r"C:/Users/thoma/Downloads"

	print(f"=== Starting High-Performance SQLite Multi-Core Pipeline ===")
	print(f"Available CPU Cores: {multiprocessing.cpu_count()} (Utilizing Intel Core i9 architecture)")

	region_groups = {}
	for park in parks_data:
		reg = park["region_keyword"]
		if reg not in region_groups:
			region_groups[reg] = []
		region_groups[reg].append(park)

	tasks = []
	for region_keyword, group_parks in region_groups.items():
		tasks.append((region_keyword, group_parks, BASE_DIR, DOWNLOADS_DIR))

	max_workers = min(len(tasks), max(1, multiprocessing.cpu_count() - 2))
	print(f"Spawning {max_workers} parallel extraction workers...")

	with multiprocessing.Pool(processes=max_workers) as pool:
		results = pool.map(process_single_region, tasks)

	print("\\n=== Batch processing execution finished! ===")
""" % base_dir
	return code
