import java.io.*;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.*;

public class CsvCreator {
  public static void main(String args[]) throws Exception {
    
    // Set DB Driver
    Class.forName("org.h2.Driver");
    // Set DB Connection
    Connection conn = DriverManager.getConnection("jdbc:h2:~/nem/nis/data/nis5_mainnet2", "", "");
    
    Statement stmt = conn.createStatement();
    ResultSet rs;

    rs = stmt.executeQuery("SELECT * FROM BLOCKS");
    
    final String br = System.getProperty("line.separator");
    final String comma = ",";

    try(BufferedWriter writer = Files.newBufferedWriter(Paths.get("blocks.csv"), Charset.defaultCharset())){
      while(rs.next()){
        StringBuilder b = new StringBuilder();
        b.append(rs.getString("TIMESTAMP")).append(comma)
         .append(rs.getString("HEIGHT")).append(comma)
         .append(rs.getString("TOTALFEE"))
         .append(br);

        writer.write(b.toString());
      }
    }

    rs = stmt.executeQuery("SELECT * FROM TRANSFERS");

    try(BufferedWriter writer = Files.newBufferedWriter(Paths.get("transfers.csv"), Charset.defaultCharset())){
      while(rs.next()){
       StringBuilder b = new StringBuilder();
       b.append(rs.getString("BLOCKID")).append(comma)
        .append(rs.getString("ID")).append(comma) // TRANSFERS$ID = TRANSFEREDMOSAICS$TRANSFERID (Foreign Key)
        .append(rs.getString("TIMESTAMP")).append(comma)
        .append(rs.getString("SENDERID")).append(comma)
        .append(rs.getString("RECIPIENTID"))
        .append(br);

       writer.write(b.toString());
      }
    }
    
    rs = stmt.executeQuery("SELECT * FROM TRANSFERREDMOSAICS");

    try(BufferedWriter writer = Files.newBufferedWriter(Paths.get("mosaictransfers.csv"), Charset.defaultCharset())){
      while(rs.next()){
        StringBuilder b = new StringBuilder();
        b.append(rs.getString("TRANSFERID")).append(comma)
         .append(rs.getString("DBMOSAICID")).append(comma)
         .append(rs.getString("QUANTITY"))
         .append(br);
        
        writer.write(b.toString());  
      }  
    }

    rs = stmt.executeQuery("SELECT * FROM MOSAICDEFINITIONS");

    try(BufferedWriter writer = Files.newBufferedWriter(Paths.get("mosaicdefinition.csv"), Charset.defaultCharset())){ 
      while(rs.next()){
        StringBuilder b = new StringBuilder();
        b.append(rs.getString("ID")).append(comma)
         .append(rs.getString("NAME")).append(comma)
         .append(rs.getString("NAMESPACEID"))
         .append(br);

        writer.write(b.toString());
      }
    }
    
    conn.close();

  }
}
