#!/usr/bin/ruby -s
# -*- Ruby -*-

# mat_anim.rb: show animation of mapping for given 2x2 matrix with gnuplot

# $Id: mat_anim.rb,v 1.12 2004/09/12 13:17:09 hira Exp $

# Copyright (c) 2004, HIRAOKA Kazuyuki <hira@ics.saitama-u.ac.jp>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#    * Redistributions of source code must retain the above copyright
#      notice,this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#    * Neither the name of the HIRAOKA Kazuyuki nor the names of its
#      contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

include Math
require 'matrix'

def usage
  name = File::basename $0
  print <<_END_
#{name}: show animation of mapping for given 2x2 matrix with gnuplot
(example)
  #{name} | gnuplot
  #{name} -s=3 | gnuplot
      ==> show sample No. 3
  #{name} -output='temp' | gnuplot
      ==> output to temp0.eps, temp1.eps, ...
  #{name} -batch | less
      ==> peek commands which were sent to gnuplot
(examples of other options)
  -frame=20 or -f=20     number of frames  (larger = smoother and slower)
  -a=0.7,-0.7,-0.3,0.1   set matrix
                            0.7 -0.7
                           -0.3  0.1
  -arrow=0.2,0.7,0.5,0.3 draw arrows from (0,0) to (0.2,0.7) and (0.5,0.3)
  -help     or -h        show this message
_END_
end

$help   ||= $h
$sample ||= $s
$frame  ||= $f

# <Memo>
#
# % (define (p2a p eig) (cal p $ diagonal(eig) $ inverse(p)))
# #<Closure: #81a0548>
#
# % (set! a (p2a (cl->m '((3 7) (5 -5))) '(.3 1.3)))
# #2A((1.0 -0.30000000000000004) (-0.7000000000000001 0.6))
# % (asym-eigenvalues a)
# (1.3000000015039888 0.2999999984960107)
#
# % (set! b (p2a (cl->m '((8 4) (6 8))) '(.5 0)))
# #2A((0.8 -0.6000000000000001) (0.4 -0.30000000000000004))
# % (asym-eigenvalues b)
# (0.5 -6.283914575407159E-17)

a = '1,-0.3,-0.7,0.6'
av1='.3,.7'
av2='.5,-.5'
b = '.8,-.6,.4,-.3'
bv1='.8,.4'
bv2='.6,.8'
c = '-0.3,1,0.6,-0.7'
$sample_opt = [
  "-a=1.5,0,0,0.5",
  "-a=0,0,0,0.5",
  "-a=1.5,0,0,-0.5",
  "-a=#{a}",
  "-a=#{a} -arrow=#{av1},#{av2}",
  "-a=#{a} -xunit=#{av1} -yunit=#{av2} -figure=",
  "-a=#{b}",
  "-a=#{b} -arrow=#{bv1},#{bv2}",
  "-a=#{b} -xunit=#{bv1} -yunit=#{bv2} -figure=",
  "-a=#{c}",
]

if $help
  usage
  exit 0
end

###########################################################
# gnuplot

# (memo)
#  gnuplot> ?color
#    gnuplot*line1Color:  red
#    gnuplot*line2Color:  green
#    gnuplot*line3Color:  blue
#    gnuplot*line4Color:  magenta
#    gnuplot*line5Color:  cyan
#    gnuplot*line6Color:  sienna
#    gnuplot*line7Color:  orange
#    gnuplot*line8Color:  coral

class Gnuplot
  attr_accessor :batch, :xmin, :xmax, :ymin, :ymax, :color, :line_width
  def initialize(batch=false)
    @xmin, @xmax, @ymin, @ymax = [-1, 1, -1, 1]
    send 'set size .721,1.0'
    @batch = batch
    @color = 3
    @line_width = 2
    clear if !@batch
  end
  def clear
    send 'set noarrow'
    dummy = '1/0'  # Sigh...
    send %|plot [#@xmin:#@xmax][#@ymin:#@ymax] #{dummy} title ""|
    show
  end
  def send(com)
    puts com
  end
  def set_term(s)
    send "set term #{s}"
  end
  def set_output(s)
    send %!set output "#{s}"!
  end
  def line(x1, y1, x2, y2, arrow=false)
    # My own clipping is needed to prevent qurious behavior of gnuplot.
    # Try this on gnuplot-3.7.2.
    #    plot [-1:1][-1:1] 1/0 title ""
    #    set arrow from 0, 0 to -2, 0
    #    replot
    x1, y1, x2, y2, head_clipped = clip x1, y1, x2, y2
    head = (arrow && !head_clipped) ? 'head' : 'nohead'
    coord = sprintf 'from %f, %f to %f, %f', x1, y1, x2, y2
    send "set arrow #{coord} #{head} lt #@color lw #@line_width"
    show
  end
  def show!
    send "replot"
    STDOUT.flush
  end
  def show
    show! if !@batch
  end
  def draw(&proc)
    @batch = true
    clear
    proc.call
    show!
    @batch = false
  end
  def animation(n = 100, t0 = 0, t1 = 1, &proc)
    tics(t0, t1, n).each{|t| draw{proc.call t}}
  end
  private
  def clip(x1, y1, x2, y2)
    dx = x2 - x1
    dy = y2 - y1
    x1, y1, dummy = clip2 x1, y1, dx, dy
    x2, y2, head_clipped = clip2 x2, y2, dx, dy
    return x1, y1, x2, y2, head_clipped
  end
  def clip2(x, y, dx, dy)
    margin = 0.5  # no certain reason on this value
    xmin, xmax = enlarge @xmin, @xmax, margin
    ymin, ymax = enlarge @ymin, @ymax, margin
    x, y, c1 = clip2_sub x, y, dx, dy, xmin, xmax
    y, x, c2 = clip2_sub y, x, dy, dx, ymin, ymax
    clipped = c1 || c2
    return x, y, clipped
  end
  def clip2_sub(u, v, du, dv, umin, umax)
    if u < umin || umax < u
      ru = [[u, umin].max, umax].min
      rv = v + ((ru - u) / du) * dv
      return [ru, rv, true]
    else
      return [u, v, false]
    end
  end
  def enlarge(a, b, margin)
    c = 0.5 * (a + b)
    d = b - a
    return [-0.5, 0.5].map{|s| c + s * (1 + margin) * d}
  end
end

def tics(from, to, n)
  (0..n).map{|i|
    r = i.to_f / n
    (1 - r) * from + r * to
  }
end

# if $test
#   g = Gnuplot::new
#   g.animation(50){|t|
#     g.color = 1
#     g.line t, 0, 0, 1-t
#     g.line 0, -t, 1-t, 0
#     g.color = 2
#     g.line -(1-t), 0, 0, t
#     g.line 0, 1-t, -t, 0
#   }
#   g.wait
# end

###########################################################
# matrix animation

### defaults

$snap ||= $term || $output
if $snap
  $frame  ||= 5
  $term   ||= 'postscript eps 24'
#   $term   ||= 'postscript eps color 24'
  $output ||= 'mat_anim_out'
end

$color        ||= 3
$arrow_color  ||= 1
$figure_color ||= 2
$frame        ||= 50
$frame = $frame.to_i
$batch        ||= $snap || $term || $output
if $sample
  $sample = 0 if $sample == true
  $sample = $sample.to_i
end

# option values for these parameters are ignored if '-sample=n' is given
$default_param = {
  'a'      => '1,-0.3,-0.7,0.6',
#   'a'      => '1.1,0.1,0.5,0.2',
  'grid'   => 10,
  'xmin'   => -1,
  'xmax'   => +1,
  'ymin'   => -1,
  'ymax'   => +1,
  'xunit'  => '1,0',
  'yunit'  => '0,1',
  'arrow'  => '1,0,0,1',
  'figure' => '-0.6,0.3,0.6,0.3:-0.4,0.6,-0.8,0:0.2,0.3,-0.4,-0.6:0.6,0.5,0.7,0.3:0.8,0.5,0.9,0.3'.gsub(':', ','),  # katakana "GE"
}

### parameter manipulation & coordinate calculation

class Plot < Hash
  def initialize
    @eye = Matrix::identity 2
    set_default
    compile
  end
  def set_default
    $default_param.each_pair{|k,v| self[k] = v}
  end
  def set_option
    set_default
    $default_param.each_key{|k| v = eval "$#{k}"; self[k] = v if v != nil}
    compile
  end
  def set_sample(n)
    set_default
    $sample_opt[n].split(/ /).each{|s|
      self[$1] = $2 if s =~ /-([a-z]+)=(.*)/
    }
    compile
    STDERR.puts "Sample #{n}"
  end
  def compile
    compile_var('frame,grid'){|x| x.to_i}
    compile_var('xmin,xmax,ymin,ymax'){|x| x.to_f}
    compile_var('a,xunit,yunit,arrow,figure'){|x| s2a x}
    a = self['a']
    @mat = Matrix[a[0..1], a[2..3]]
    @xunit = Vector[*self['xunit']]
    @yunit = Vector[*self['yunit']]
    @fig = generate_fig
  end
  def compile_var(s, &conv)
    s.split(/,/).each{|k| self[k] = conv.call(self[k])}
  end
  def s2a(s)
    s.is_a?(Array) ? s : s.split(/,/).map{|z| z.to_f}
  end
  def draw_at(t, g)
    @fig.draw m_at(t), g
  end
  def m_at(t)
    (1 - t) * @eye + t * @mat
  end
  def v_for(x, y)
    @xunit * x + @yunit * y
  end
  def add_line(f, x1, y1, x2, y2, *rest)
    args = [v_for(x1, y1), v_for(x2, y2)] + rest
    f.add_line *args
  end
  def generate_fig
    f = Fig::new
    eval 'xmin,xmax,ymin,ymax,grid,arrow,figure'.split(/,/).map{|k|
      "@#{k} = self['#{k}']"
    }.join ';'
    xs = tics(@xmin, @xmax, @grid)
    ys = tics(@ymin, @ymax, @grid)
    xs.each{|x| add_line f, x, @ymin, x, @ymax}
    ys.each{|y| add_line f, @xmin, y, @xmax, y}
    while !@arrow.empty?
      x = @arrow.shift
      y = @arrow.shift
      add_line f, 0, 0, x, y, $arrow_color, true, 5
    end
    while !@figure.empty?
      x1 = @figure.shift
      y1 = @figure.shift
      x2 = @figure.shift
      y2 = @figure.shift
      add_line f, x1, y1, x2, y2, $figure_color, false, 3
    end
    return f
  end
  def matrix
    @mat
  end
end

### line & figure

class Line
  attr_accessor :v1, :v2, :color, :arrow, :line_width
  def initialize(v1, v2, color=$color, arrow=false, line_width=1)
    @v1 = v1
    @v2 = v2
    @color, @arrow, @line_width = [color, arrow, line_width]
  end
  def draw(mat, g)
    w1 = mat * @v1
    w2 = mat * @v2
    g.color = @color
    g.line_width = @line_width
    g.line w1[0], w1[1], w2[0], w2[1], @arrow
  end
end

class Fig < Array
  def add_line(*args)
    self.push Line::new(*args)
  end
  def draw(mat, g)
    self.each{|z| z.draw mat, g}
  end
end

### misc.

class Matrix
  def to_table_str
    m = row_size
    n = column_size
    (0...m).to_a.map{|i|
      (0...n).to_a.map{|j| sprintf "% 2.5f", self[i,j]}.join ' '
    }.join "\n"
  end
end

def show_matrix(plot)
  if !$batch
    STDERR.puts 'Matrix A ='
    STDERR.puts plot.matrix.to_table_str
    STDERR.puts '-- q: quit, n: next sample, p: previous sample, other: repeat --'
  end
end

def set_out(g, count)
  if $output
    out = "#{$output}#{count}.eps"
    STDERR.puts "Output to #{out}"
    g.set_output out
  end
end

def next_sample(d, plot)
  $sample = ($sample || -1).to_i + d
  n = $sample % $sample_opt.length
  plot.set_sample n
  show_matrix plot
end

### main

g = Gnuplot::new $term
g.set_term $term if $term

$plot = Plot::new
$sample ? $plot.set_sample($sample) : $plot.set_option

show_matrix $plot

begin
  c = "0"
  set_out g, c
  g.animation($frame){|t|
    set_out g, c
    $plot.draw_at t, g
    c.succ!
  }
  com = STDIN.gets.chop if !$batch
  case com
  when 'q'
    break
  when 'n'
    next_sample +1, $plot
  when 'p'
    next_sample -1, $plot
  end
end while !$batch
