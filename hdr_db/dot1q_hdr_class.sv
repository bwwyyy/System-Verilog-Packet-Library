/*
Copyright (c) 2011, Sachin Gandhi
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// ----------------------------------------------------------------------
//  This hdr_class generates the IEEE 802.1q C-Tag and IEEE 802.1ad S-Tag
//  802.1q/802.1ad Tag Format
//  +-------------+
//  | cos[2:0]    | 
//  +-------------+
//  | cfi         | 
//  +-------------+
//  | vlan[11:0]  |
//  +-------------+
//  | etype[15:0] |
//  +-------------+
// ----------------------------------------------------------------------

class dot1q_hdr_class extends hdr_class; // {

  // ~~~~~~~~~~ Class members ~~~~~~~~~~
  rand bit [2:0]  cos;
  rand bit        cfi;
  rand bit [11:0] vlan;
  rand bit [15:0] etype;

  // ~~~~~~~~~~ Local Variables ~~~~~~~~~~

  // ~~~~~~~~~~ Control variables ~~~~~~~~~~

  // ~~~~~~~~~~ Constraints begins ~~~~~~~~~~

  constraint dot1q_hdr_user_constraint
  {
  }

  constraint legal_total_hdr_len
  {
    `LEGAL_TOTAL_HDR_LEN_CONSTRAINTS;
  }

  constraint legal_etype
  {
    `LEGAL_ETH_TYPE_CONSTRAINTS;
  }

  constraint legal_hdr_len
  {
    hdr_len == 4;
  }
  

  // ~~~~~~~~~~ Task begins ~~~~~~~~~~

  function new (pktlib_main_class plib,
                int               inst_no,
                int               hid_ctrl = 0); // {
    super.new (plib);
    this.inst_no = inst_no;
    case (hid_ctrl) // {
      1 : // {
      begin // {
          hid      = ALT1Q_HID;
          $sformat (hdr_name, "alt1q[%0d]",inst_no);
      end // }
      2 : // {
      begin // {
          hid      = STAG_HID;
          $sformat (hdr_name, "stag[%0d]",inst_no);
      end // }
      default : // {
      begin // {
          hid      = DOT1Q_HID;
          $sformat (hdr_name, "dot1q[%0d]",inst_no);
      end // }
    endcase // }
    super.update_hdr_db (hid, inst_no);
  endfunction : new // }

  function void pre_randomize (); // {
    if (super) super.pre_randomize();
  endfunction : pre_randomize // }

  task pack_hdr(ref   bit [7:0] pkt [],
                ref   int       index,
                input bit       last_pack = 1'b0); // {
    // pack class members
    pack_vec = {cos, cfi, vlan, etype};
    harray.pack_bit(pkt, pack_vec, index, hdr_len*8);
    // pack next hdr
    if (~last_pack)
        this.nxt_hdr.pack_hdr (pkt, index);
  endtask : pack_hdr // }

  task unpack_hdr (ref   bit [7:0] pkt   [],
                   ref   int       index,
                   ref   hdr_class hdr_q [$],
                   input int       mode        = DUMB_UNPACK,
                   input bit       last_unpack = 1'b0); // {
    hdr_class lcl_class;
    // unpack class members
    hdr_len   = 4;
    start_off = index;
    harray.unpack_array (pkt, pack_vec, index, hdr_len);
    {cos, cfi, vlan, etype} = pack_vec;
    // get next hdr and update common nxt_hdr fields
    if (mode == SMART_UNPACK)
    begin // {
        $cast (lcl_class, this);
        if (pkt.size > index)
            super.update_nxt_hdr_info (lcl_class, hdr_q, get_hid_from_etype (etype));
        else
            super.update_nxt_hdr_info (lcl_class, hdr_q, DATA_HID);
    end // }
    // unpack next hdr
    if (~last_unpack)
        this.nxt_hdr.unpack_hdr (pkt, index, hdr_q, mode);
    // update all hdr
    if (mode == SMART_UNPACK)
        super.all_hdr = hdr_q;
  endtask : unpack_hdr // }

  task cpy_hdr (hdr_class cpy_cls,
                bit       last_unpack = 1'b0); // {
    dot1q_hdr_class lcl;
    super.cpy_hdr (cpy_cls);
    $cast (lcl, cpy_cls);
    // ~~~~~~~~~~ Class members ~~~~~~~~~~
    this.cos         = lcl.cos;
    this.cfi         = lcl.cfi;
    this.vlan        = lcl.vlan;
    this.etype       = lcl.etype;
    if (~last_unpack)
        this.nxt_hdr.cpy_hdr (cpy_cls.nxt_hdr, last_unpack);
  endtask : cpy_hdr // }

  // This task displays all the feilds of individual hdrs used
  task display_hdr (pktlib_display_class hdis,
                    hdr_class            cmp_cls,
                    int                  mode         = DISPLAY,
                    bit                  last_display = 1'b0); // {
    dot1q_hdr_class lcl;
    $cast (lcl, cmp_cls);
    hdis.display_fld (mode, hdr_name, "cos",   03, HEX, BIT_VEC, cos,   lcl.cos);
    hdis.display_fld (mode, hdr_name, "cfi",   01, HEX, BIT_VEC, cfi,   lcl.cfi);
    hdis.display_fld (mode, hdr_name, "vlan",  12, HEX, BIT_VEC, vlan,  lcl.vlan);
    hdis.display_fld (mode, hdr_name, "etype", 16, HEX, BIT_VEC, etype, lcl.etype, '{}, '{}, get_etype_name(etype));
    if (~last_display & (cmp_cls.nxt_hdr.hid == nxt_hdr.hid))
        this.nxt_hdr.display_hdr (hdis, cmp_cls.nxt_hdr, mode);
  endtask : display_hdr // }

endclass : dot1q_hdr_class // }