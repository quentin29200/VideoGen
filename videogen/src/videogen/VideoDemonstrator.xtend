package videogen

import java.util.HashMap
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.junit.Test
import org.xtext.example.mydsl.VideoGenStandaloneSetupGenerated
import org.xtext.example.mydsl.videoGen.AlternativeVideoSeq
import org.xtext.example.mydsl.videoGen.MandatoryVideoSeq
import org.xtext.example.mydsl.videoGen.OptionalVideoSeq
import org.xtext.example.mydsl.videoGen.VideoGeneratorModel

import static org.junit.Assert.*
import java.util.Random
import org.xtext.example.mydsl.videoGen.VideoSeq
import playlist.Playlist
import playlist.PlaylistFactory
import java.io.BufferedWriter
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.io.IOException
import java.io.Writer
import playlist.VideoFile
import java.io.BufferedReader
import java.io.InputStreamReader

class VideoDemonstrator {
	static Writer writer
	
	def loadVideoGenerator(URI uri) {
		new VideoGenStandaloneSetupGenerated().createInjectorAndDoEMFRegistration()
		var res = new ResourceSetImpl().getResource(uri, true);
		res.contents.get(0) as VideoGeneratorModel
	}
	
	def saveVideoGenerator(URI uri, VideoGeneratorModel pollS) {
		var Resource rs = new ResourceSetImpl().createResource(uri); 
		rs.getContents.add(pollS); 
		rs.save(new HashMap());
	}
	
	@Test
	def testFFMPEG() {
		// loading
		var videoGen = loadVideoGenerator(URI.createURI("foo2.videogen")) 
		assertNotNull(videoGen)
		var strPlaylist = ""
		
		val seqs =videoGen.videoseqs
				
		// MODEL MANAGEMENT (ANALYSIS, TRANSFORMATION)
		for (VideoSeq vseq : seqs) {
			if (vseq instanceof MandatoryVideoSeq) {
				val fileLocation = (vseq as MandatoryVideoSeq).description.location;
				strPlaylist += 'file \'' + fileLocation + '\'\r\n'	
			}
			else if (vseq instanceof OptionalVideoSeq) {
				val i = new Random().nextInt(1)
				if (i == 0) {
					val fileLocation = (vseq as OptionalVideoSeq).description.location;
					strPlaylist += 'file \'' + fileLocation + '\'\r\n'		
				} else {
					// no
					 
				}
			}
			else { // alternative
				val alt = (vseq as AlternativeVideoSeq)
				val nAlts = alt.videodescs.size
				if (nAlts > 1) {
					val i =  new Random().nextInt(nAlts)
					val fileLocation = alt.videodescs.get(i).location
					strPlaylist += 'file \'' + fileLocation + '\'\r\n'										
				}
			}
		}		
		createFile("script.txt",strPlaylist)		
	}
		
	@Test
	def testM3U() {
		// loading
		var videoGen = loadVideoGenerator(URI.createURI("foo2.videogen")) 
		assertNotNull(videoGen)
		
		val seqs =videoGen.videoseqs
		
		val pl = PlaylistFactory.eINSTANCE.createPlaylist
				
		// MODEL MANAGEMENT (ANALYSIS, TRANSFORMATION)
		for (VideoSeq vseq : seqs) {
			if (vseq instanceof MandatoryVideoSeq) {
				val fileLocation = (vseq as MandatoryVideoSeq).description.location;
				val vf = PlaylistFactory.eINSTANCE.createVideoFile		
				vf.path = fileLocation
				vf.duration = getDuration(fileLocation)
				pl.files.add(vf)
			}
			else if (vseq instanceof OptionalVideoSeq) {
				val i = new Random().nextInt(1)
				if (i == 0) {
					val fileLocation = (vseq as OptionalVideoSeq).description.location;
					val vf = PlaylistFactory.eINSTANCE.createVideoFile		
					vf.path = fileLocation
					vf.duration = getDuration(fileLocation)
					pl.files.add(vf)		
				} else {
					// no
					 
				}
			}
			else { // alternative
				val alt = (vseq as AlternativeVideoSeq)
				val nAlts = alt.videodescs.size
				if (nAlts > 1) {
					val i =  new Random().nextInt(nAlts)
					val fileLocation = alt.videodescs.get(i).location
					val vf = PlaylistFactory.eINSTANCE.createVideoFile		
					vf.path = fileLocation
					vf.duration = getDuration(fileLocation)
					pl.files.add(vf)										
				}
			}
		}
		generateM3U(pl)
		generateM3UEXT(pl)
	}
		

	@Test
	def test1() {
		// loading
		var videoGen = loadVideoGenerator(URI.createURI("foo2.videogen")) 
		assertNotNull(videoGen)
		assertEquals(7, videoGen.videoseqs.size)			
		// MODEL MANAGEMENT (ANALYSIS, TRANSFORMATION)
		videoGen.videoseqs.forEach[videoseq | 
			if (videoseq instanceof MandatoryVideoSeq) {
				val desc = (videoseq as MandatoryVideoSeq).description
				if(desc.videoid.isNullOrEmpty)  desc.videoid = genID()  				
			}
			else if (videoseq instanceof OptionalVideoSeq) {
				val desc = (videoseq as OptionalVideoSeq).description
				if(desc.videoid.isNullOrEmpty) desc.videoid = genID() 
			}
			else {
				val altvid = (videoseq as AlternativeVideoSeq)
				if(altvid.videoid.isNullOrEmpty) altvid.videoid = genID()
				for (vdesc : altvid.videodescs) {
					if(vdesc.videoid.isNullOrEmpty) vdesc.videoid = genID()
				}
			}
		]
	// serializing
	saveVideoGenerator(URI.createURI("foo2bis.xmi"), videoGen)
	saveVideoGenerator(URI.createURI("foo2bis.videogen"), videoGen)
		
	printToHTML(videoGen)
		 
			
	}
	
	def void printToHTML(VideoGeneratorModel videoGen) {
		//var numSeq = 1
		println("<ul>")
		videoGen.videoseqs.forEach[videoseq | 
			if (videoseq instanceof MandatoryVideoSeq) {
				val desc = (videoseq as MandatoryVideoSeq).description
				if(!desc.videoid.isNullOrEmpty)  
					println ("<li>" + desc.videoid + "</li>")  				
			}
			else if (videoseq instanceof OptionalVideoSeq) {
				val desc = (videoseq as OptionalVideoSeq).description
				if(!desc.videoid.isNullOrEmpty) 
					println ("<li>" + desc.videoid + "</li>") 
			}
			else {
				val altvid = (videoseq as AlternativeVideoSeq)
				if(!altvid.videoid.isNullOrEmpty) 
					println ("<li>" + altvid.videoid + "</li>")
				if (altvid.videodescs.size > 0) // there are vid seq alternatives
					println ("<ul>")
				for (vdesc : altvid.videodescs) {
					if(!vdesc.videoid.isNullOrEmpty) 
						println ("<li>" + vdesc.videoid + "</li>")
				}
				if (altvid.videodescs.size > 0) // there are vid seq alternatives
					println ("</ul>")
			}
		]
		println("</ul>")
	}
	
	static var i = 0;
		
	def genID() {
		"v" + i++
	}
	
	def static void createFile(String filename, String content){
		try {
		    writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(filename), "utf-8"));
		    writer.write(content);
		} catch (IOException ex) {
		  System.out.println(ex.message)
		} finally {
		   try {writer.close();} catch (Exception ex) {/*ignore*/}
		}
  	}
  	
	def static int getDuration(String path) {
		var Process process = Runtime.getRuntime().exec("ffprobe -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \"" + path + "\"");
		//System.out.println("ffprobe -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \"" + path + "\"")
		process.waitFor();
		
		var BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

		var String line = "";
		var String outputJson = "";
	    while ((line = reader.readLine()) != null) {
	        outputJson = outputJson + line;
	    }
	    return Math.round(Float.parseFloat(outputJson))-1;
	}
  	
  	def static void generateM3U(Playlist p){
  		var strPlaylist = ""
		
		for (VideoFile v : p.getFiles()) {
				val fileLocation = v.getPath();
				strPlaylist += fileLocation + '\r\n'	
		}
		
		createFile("playlist.m3u",strPlaylist)		
  	}
  	
  	def static void generateM3UEXT(Playlist p){
  		var strPlaylist = '#EXTM3U \r\n'
		
		for (VideoFile v : p.getFiles()) {
				strPlaylist += "#EXT-X-DISCONTINUITY\r\n"
				strPlaylist += "#EXTINF:" + v.getDuration() + "\r\n"
				val fileLocation = v.getPath();
				strPlaylist += fileLocation + '\r\n'	
		}
		createFile("playlistEXT.m3u",strPlaylist)		
  	}
  	
  	
  	
}