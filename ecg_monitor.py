import math
import time
import threading
from collections import deque
import numpy as np
from scipy.signal import find_peaks

from kivy.app import App
from kivy.lang import Builder
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.graphics import Line, Color, Rectangle

KV = '''
<ECGMonitor>:
    orientation: 'vertical'
    padding: 20
    spacing: 15

    canvas.before:
        Color:
            rgba: 0.05,0.05,0.07,1
        Rectangle:
            pos: self.pos
            size: self.size

    Label:
        text: "Real-Time ECG Monitor"
        font_size: '28sp'
        bold: True
        size_hint_y: 0.1
        color: 0.2,0.8,1,1

    BoxLayout:
        size_hint_y:0.15

        Label:
            text:"Heart Rate:"
            font_size:'24sp'

        Label:
            id:bpm_label
            text:"-- BPM"
            font_size:'34sp'
            bold:True
            color:1,0.3,0.3,1

    ECGGraph:
        id:ecg_graph
        size_hint_y:0.75
        canvas.before:
            Color:
                rgba:0.1,0.1,0.1,1
            Rectangle:
                pos:self.pos
                size:self.size
'''

Builder.load_string(KV)


class ECGGraph(Widget):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        with self.canvas:
            Color(0.2,1,0.2,1)
            self.line = Line(points=[],width=1.5)

    def update_graph(self,data_buffer):

        if len(data_buffer)<2:
            return

        width,height = self.width,self.height
        x_start,y_start = self.x,self.y

        d_max=max(data_buffer)
        d_min=min(data_buffer)

        if d_max==d_min:
            d_max+=1

        range_val=d_max-d_min

        num_points=len(data_buffer)
        step_x=width/(num_points-1)

        points=[]

        for i,val in enumerate(data_buffer):

            x=x_start+i*step_x
            y=y_start+(val-d_min)/range_val*height*0.8+height*0.1

            points.extend([x,y])

        self.line.points=points


class ECGMonitor(BoxLayout):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.sampling_rate=100
        self.max_samples=300

        self.data_buffer=deque([0]*self.max_samples,maxlen=self.max_samples)

        self.is_running=True

        self.data_thread=threading.Thread(target=self.receive_sensor_data)
        self.data_thread.daemon=True
        self.data_thread.start()

        Clock.schedule_interval(self.refresh_graph,1.0/30.0)
        Clock.schedule_interval(self.calculate_heart_rate,1.0)


    def receive_sensor_data(self):

        while self.is_running:

            t=time.time()

            beat_phase=(t%1.0)

            val=0.02*math.sin(t*5)

            # P wave
            if 0.1<beat_phase<0.18:
                val+=0.15*math.sin((beat_phase-0.1)*math.pi*8)

            # Q dip
            if 0.20<beat_phase<0.23:
                val-=0.3

            # R peak
            if 0.23<beat_phase<0.26:
                val+=1.2

            # S dip
            if 0.26<beat_phase<0.30:
                val-=0.5

            # T wave
            if 0.40<beat_phase<0.55:
                val+=0.25*math.sin((beat_phase-0.40)*math.pi*5)

            # small noise
            val+=np.random.normal(0,0.02)

            self.data_buffer.append(val)

            time.sleep(1.0/self.sampling_rate)


    def refresh_graph(self,dt):

        self.ids.ecg_graph.update_graph(list(self.data_buffer))


    def calculate_heart_rate(self,dt):

        data=list(self.data_buffer)

        peaks,_=find_peaks(data,
                           distance=int(self.sampling_rate*0.2),
                           prominence=0.6)

        if len(peaks)>=2:

            avg_distance=np.mean(np.diff(peaks))

            bpm=(60.0*self.sampling_rate)/avg_distance

            if 40<=bpm<=220:
                self.ids.bpm_label.text=f"{int(bpm)} BPM"
            else:
                self.ids.bpm_label.text="Reading..."

        else:
            self.ids.bpm_label.text="Detecting..."


class ECGApp(App):

    def build(self):
        return ECGMonitor()

    def on_stop(self):
        self.root.is_running=False


if __name__=="__main__":
    ECGApp().run()
