DROP FUNCTION IF EXISTS zigzag;
DELIMITER $$
CREATE FUNCTION zigzag(n bigint) RETURNS bigint
  DETERMINISTIC
BEGIN
  RETURN (abs(n) << 1) + IF(n<0, -1, 0);
END
$$

DROP FUNCTION IF EXISTS dezigzag;
CREATE FUNCTION dezigzag(n bigint unsigned) RETURNS bigint
DETERMINISTIC
BEGIN
  RETURN n/2 * IF((n & 1)>0, -1, 1);
END;
$$

DROP FUNCTION IF EXISTS get_varint;
CREATE FUNCTION get_varint(proto_in blob) RETURNS bigint
	DETERMINISTIC
BEGIN
	DECLARE header bigint;
	DECLARE total bigint;
	DECLARE proto text;
	DECLARE bytes bigint;

	SET total = 0;
	SET proto = hex(proto_in);
	SET bytes = 0;

	mainloop: LOOP
		SET header = cast(CONV(left(proto, 2),16,10) as unsigned);
		SET proto = mid(proto, 3);
		SET total = total + ((header & b'01111111') << (7 * bytes));
		IF header>>7 = 0 THEN
			LEAVE mainloop;
		END IF;
		SET bytes = bytes + 1;
	END LOOP;

	RETURN total;
END;
$$

DROP FUNCTION IF EXISTS get_varint__wire_size;
CREATE FUNCTION get_varint__wire_size(varint_in bigint) RETURNS bigint
	DETERMINISTIC
BEGIN
	DECLARE v_out bigint;
	DECLARE varint bigint;

	SET v_out = 1;
	SET varint = varint_in;

	mainloop: LOOP
		SET varint = varint>>7;
		IF varint=0 THEN
			LEAVE mainloop;
		END IF;
		SET v_out = v_out + 1;
	END LOOP;

	RETURN v_out;
END;
$$

DROP FUNCTION IF EXISTS proto_decode;
CREATE FUNCTION proto_decode(id_in INT, proto_in BLOB) RETURNS bigint
    DETERMINISTIC
BEGIN
  DECLARE header bigint;
  DECLARE header_redux bigint;
  DECLARE id INT;
  DECLARE value INT;
  DECLARE proto BLOB;
  SET proto = proto_in;
   SET value = 99;
 
  mainloop: LOOP
    SET value = 0;
    SET header = get_varint(proto);
    SET proto = substr(proto, 1 + get_varint__wire_size(header));
    SET id = header>>3;
    CASE (header & 7)
    	WHEN 0 THEN
    		SET value = get_varint(proto);
    		SET proto = substr(proto, 1 + get_varint__wire_size(value));
--    		SET value = 32;
    	WHEN 1 THEN
--    		SET value = cast(left(proto, 8) as unsigned);
    		SET proto = substr(proto, 8);
    	WHEN 5 THEN
--    		SET value = cast(left(proto, 4) as unsigned);
    		SET proto = substr(proto, 4);
    	WHEN 2 THEN
    		SET value = get_varint(proto); #this is actually field size
--    		SET proto = substr(proto, 1 + value + get_varint__wire_size(value));
    		SET proto = substr(proto, 1 + get_varint__wire_size(value));
	  		SET proto = substr(proto, 1 + value);
	   	ELSE
		    LEAVE mainloop;
    END CASE;

    IF id = id_in THEN
      LEAVE mainloop;
    END IF;
    IF length(proto)=0 THEN
  	  SET value = 0;
      LEAVE mainloop;
    END IF;
    
  END LOOP;

  RETURN value;
 END
$$

DROP FUNCTION IF EXISTS proto_decode_string;
CREATE FUNCTION proto_decode_string(id_in INT, proto_in BLOB) RETURNS text
    DETERMINISTIC
BEGIN
  DECLARE header bigint;
  DECLARE header_redux bigint;
  DECLARE id INT;
  DECLARE value INT;
  DECLARE v_out TEXT;
  DECLARE proto BLOB;
  SET proto = proto_in;

  mainloop: LOOP
    set v_out = "";
    SET header = get_varint(proto);
    SET proto = substr(proto, 1 + get_varint__wire_size(header));
    SET id = header>>3;
    CASE (header & 7)
    	WHEN 0 THEN
    		SET value = get_varint(proto);
    		SET proto = substr(proto, 1 + get_varint__wire_size(value));
    	WHEN 1 THEN
    		SET value = cast(left(proto, 8) as unsigned);
    		SET proto = substr(proto, 8);
    	WHEN 5 THEN
    		SET value = cast(left(proto, 4) as unsigned);
    		SET proto = substr(proto, 4);
    	WHEN 2 THEN
    		SET value = get_varint(proto); #this is actually field size
    		SET proto = substr(proto, 1 + get_varint__wire_size(value));
		    IF id = id_in THEN
		      SET v_out = convert(left(proto, value) using utf8);
		      LEAVE mainloop;
		    END IF;
    		SET proto = substr(proto, 1 + value);
    	ELSE
    		SET value = 0;
		    LEAVE mainloop;
    END CASE;

    IF length(proto)=0 THEN
      LEAVE mainloop;
    END IF;
    
  END LOOP;

  RETURN v_out;
 END
$$
